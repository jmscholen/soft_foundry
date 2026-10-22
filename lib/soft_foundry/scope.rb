# frozen_string_literal: true

require "yaml"
require "date"
require_relative "control_plane"
require_relative "change_record"
require_relative "declarations"
require_relative "errors"

module SoftFoundry
  # The one decision about which changed paths matter to a change record:
  # staleness (Gate), sizing, the advisories, and every consumer of those
  # read what this reports and add no logic of their own.
  #
  # A record with no declared scope is whole-repository: it does not use
  # this class to decide staleness at all, and behaves exactly as it did
  # before scopes existed. A record with a scope is stale for a changed
  # code path that is in its scope, in the repository's shared core, or
  # claimed by no active record's scope; and for any edit, after the
  # evidence, to the declarations themselves. A path claimed only by
  # another active record's scope is that record's business.
  class Scope
    # reason is one of IN_SCOPE, SHARED_CORE, UNCLAIMED, CLAIMED, or
    # "declaration changed: <what>". `claimed_by` names the claiming record.
    Entry = Data.define(:path, :reason, :claimed_by) do
      def stale? = reason != CLAIMED
      def to_line = "#{path}: #{claimed_by ? "#{reason} (#{claimed_by})" : reason}"
    end

    # `paths` is every path the diff touched, code or not (sizing needs it
    # to find access-control edits); `entries` classifies the code paths.
    Result = Data.define(:applied, :entries, :paths, :where, :error) do
      def reasons = entries.select(&:stale?)
      def stale? = !error.nil? || !reasons.empty?
    end

    IN_SCOPE = "in scope"
    SHARED_CORE = "shared core"
    UNCLAIMED = "unclaimed"
    CLAIMED = "claimed by another record"
    WHOLE_REPOSITORY = "whole repository"
    PROFILE = ".ai/repository.yml"
    POLICY = ".ai/policies/check-sizing.yml"

    # The commit a record's branch points at when that branch exists and is
    # not the one checked out; nil when the checked-out worktree is the
    # measure. "After" is measured on the record's own branch: a change
    # stacked on another change's branch covers its own code with its own
    # record.
    def self.tip_for(record, git)
      branch = record.metadata.dig("git", "branch").to_s
      branch != git.branch.to_s ? git.branch_tip(branch) : nil
    end

    def initialize(record, git:)
      @record = record
      @plane = record.control_plane
      @git = git
    end

    def scoped? = !@record.scope.empty?

    def applied
      scoped? ? @record.scope.join(", ") : WHOLE_REPOSITORY
    end

    # The commit that recorded the plan phase complete: the diff base for
    # the change as a whole (sizing, advisories). Nil until it is recorded.
    def change_base
      plan = @plane.phase("plan")
      plan ? @record.recorded_commit(plan, git: @git) : nil
    end

    # Classifies what changed since `sha` for a scoped record. With
    # `declarations`, an edit since `sha` to the record's scope, the
    # shared core, the access-control globs or the sizing policy counts
    # too. Any git failure is reported as an error, never as no change.
    def measure(sha, declarations: true)
      tip = self.class.tip_for(@record, @git)
      where = tip ? " on branch #{@record.metadata.dig('git', 'branch')}" : ""
      paths = @git.diff_paths(sha, tip)
      code = paths.select { |p| ControlPlane.match_any?(p, @plane.code_globs) }
      entries = code.map { |path| classify(path) }
      entries.concat(declaration_changes(sha, tip, paths)) if declarations
      Result.new(applied: applied, entries: entries, paths: paths, where: where, error: nil)
    rescue GitError, Psych::Exception => e
      Result.new(applied: applied, entries: [], paths: [], where: "", error: e.message)
    end

    # The active records other than this one that claim a path, by slug.
    def claimants(path)
      siblings.select { |_, scope| ControlPlane.match_any?(path, scope) }.map(&:first)
    end

    # Active records whose scope overlaps this record's: a glob in common,
    # or one glob's literal prefix lying beneath the other's.
    def overlapping_records
      siblings.select { |_, scope| @record.scope.any? { |a| scope.any? { |b| globs_overlap?(a, b) } } }.map(&:first)
    end

    private

    def classify(path)
      return Entry.new(path, SHARED_CORE, nil) if ControlPlane.match_any?(path, @plane.shared_core)
      return Entry.new(path, IN_SCOPE, nil) if ControlPlane.match_any?(path, @record.scope)
      owners = claimants(path)
      owners.empty? ? Entry.new(path, UNCLAIMED, nil) : Entry.new(path, CLAIMED, owners.join(", "))
    end

    def globs_overlap?(first, second)
      a = first[/\A[^*?\[{]*/]
      b = second[/\A[^*?\[{]*/]
      a.start_with?(b) || b.start_with?(a)
    end

    # [slug, scope] for each other record that is active (not closed) and
    # has a well-formed scope. A closed or malformed record claims nothing,
    # so it can never hide a stale path. Read from disk once per decision.
    def siblings
      @siblings ||= Dir.glob(File.join(@record.root, "changes", "*", "metadata.yml")).sort.filter_map do |file|
        slug = File.basename(File.dirname(file))
        next if slug == @record.slug
        other = ChangeRecord.new(@record.root, slug, control_plane: @plane)
        raw = other.metadata["scope"]
        next if other.closed? || !Declarations.claimable?(raw)
        [slug, raw]
      rescue Psych::Exception, SystemCallError, ArgumentError
        nil
      end
    end

    # Declaration files that appear in the diff and whose declared value
    # differs between `sha` and now. A declaration absent then and present
    # now counts; an unreadable one fails closed (GitError / Psych).
    def declaration_changes(sha, tip, paths)
      meta = "changes/#{@record.slug}/metadata.yml"
      found = []
      if paths.include?(meta)
        found << declaration_entry(meta, "scope") if declared(sha, tip, meta, ["scope"]) != declared(nil, tip, meta, ["scope"])
      end
      if paths.include?(PROFILE)
        %w[shared_core access_control].each do |key|
          found << declaration_entry(PROFILE, key) if declared(sha, tip, PROFILE, [key]) != declared(nil, tip, PROFILE, [key])
        end
      end
      if paths.include?(POLICY) && text_at(sha, POLICY) != text_at(nil, POLICY, tip: tip)
        found << declaration_entry(POLICY, "check-sizing policy")
      end
      found
    end

    def declaration_entry(path, what) = Entry.new(path, "declaration changed: #{what}", nil)

    # The list declared under `key` in a YAML file at `sha` (nil sha: now),
    # normalised so absent, nil and [] are the same declaration.
    def declared(sha, tip, path, keys)
      text = text_at(sha, path, tip: tip)
      data = text.nil? ? {} : YAML.safe_load(text, permitted_classes: [Time, Date], aliases: false)
      data = {} unless data.is_a?(Hash)
      keys.map { |k| Array(data[k]) }
    end

    # File contents at `sha`, or as they are now: on the record's branch tip
    # when it is not checked out, else the worktree. Nil when absent.
    def text_at(sha, path, tip: nil)
      return @git.blob!(sha, path) if sha
      return @git.blob!(tip, path) if tip
      file = File.join(@record.root, path)
      File.file?(file) ? File.read(file) : nil
    end
  end
end
