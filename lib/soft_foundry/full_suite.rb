# frozen_string_literal: true

require "yaml"
require "date"
require_relative "errors"

module SoftFoundry
  # The structural check on a verification's full-suite record. Soft
  # Foundry never runs the application's tests: this reads what a record
  # says was run, and checks that it names the tree of the evidence commit.
  # A pass means a recorded run names this tree with a recorded outcome, not
  # that the suite passed.
  #
  # tests.yml in the verification directory may hold:
  #
  #   full_suite:
  #     tree: <git tree hash of the evidence commit>
  #     command: <what was run>
  #     outcome: passed
  #
  # or cite another record's run instead of running the suite again:
  #
  #   full_suite:
  #     cite: <slug of another change record>
  #
  # The tree is recomputed from git; a recorded hash is never trusted alone.
  class FullSuite
    Outcome = Data.define(:outcome, :detail)

    SLUG = /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/
    FIX = "run the full suite on this tree and record it in tests.yml"

    def initialize(record, git:)
      @record = record
      @plane = record.control_plane
      @git = git
    end

    # Checks `block` (the `full_suite:` value, or nil) against the tree of
    # `evidence_sha`. `required` is true when the computed size owes a full
    # run at verify; `owed_note` says why a missing run is not yet a failure.
    def evaluate(block, evidence_sha:, required:, owed_note:)
      return missing(required, owed_note) if block.nil?
      return failed("full_suite must be a mapping with tree, command and outcome, or a cite") unless block.is_a?(Hash)
      tree = @git.tree_of(evidence_sha)
      block.key?("cite") ? cited(block["cite"], tree) : recorded(block, tree)
    rescue GitError => e
      failed(e.message)
    end

    private

    def missing(required, owed_note)
      return failed("no full-suite run is recorded and the computed size is the full suite at verify") if required
      Outcome.new(:skip, owed_note)
    end

    def failed(cause) = Outcome.new(:fail, "fail: #{cause}; #{FIX}")

    def recorded(block, tree)
      return failed("full_suite.tree '#{block['tree']}' is not the tree of the evidence commit (#{tree[0, 12]})") unless block["tree"].to_s == tree
      return failed("full_suite.command is missing") if block["command"].to_s.strip.empty?
      return failed("full_suite.outcome is '#{block['outcome']}', not passed") unless block["outcome"].to_s == "passed"
      Outcome.new(:pass, "recorded run on tree #{tree[0, 12]}, outcome passed (a record, not a test result)")
    end

    def cited(slug, tree)
      slug = slug.to_s
      return failed("cite '#{slug}' is not a change record name") unless slug.match?(SLUG) && !slug.include?("..")
      return failed("a record cannot cite its own run") if slug == @record.slug
      file = cited_file(slug)
      return failed("cited record '#{slug}' has no verification record") unless file
      data = YAML.safe_load_file(file, permitted_classes: [Time, Date], aliases: false)
      run = data.is_a?(Hash) ? data["full_suite"] : nil
      return failed("cited record '#{slug}' records no full-suite run of its own (a citation is one level deep)") unless run.is_a?(Hash) && run.key?("tree")
      return failed("cited run's tree #{run['tree'].to_s[0, 12]} is not this evidence commit's tree #{tree[0, 12]}") unless run["tree"].to_s == tree
      return failed("cited run's outcome is '#{run['outcome']}', not passed") unless run["outcome"].to_s == "passed"
      dirty = @git.code_dirty_paths(@plane.code_globs)
      return failed("code paths are dirty (#{dirty.first(3).join(', ')}); untracked and ignored files are outside the tree hash, so a dirty worktree cannot reuse a result") unless dirty.empty?
      Outcome.new(:pass, "cites #{slug}: recorded run on tree #{tree[0, 12]}, outcome passed (a record, not a test result)")
    rescue Psych::Exception
      failed("cited record '#{slug}' has an unreadable tests.yml")
    end

    # The cited record's tests.yml, resolved under changes/ only.
    def cited_file(slug)
      verify = @plane.phase("verify")
      root = File.join(@record.root, "changes")
      file = File.join(root, slug, verify.output, "tests.yml")
      return nil unless File.file?(file) && Dir.children(root).include?(slug)
      real = File.realpath(file)
      real.start_with?("#{File.realpath(root)}#{File::SEPARATOR}") ? real : nil
    end
  end
end
