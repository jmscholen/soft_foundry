# frozen_string_literal: true

require "yaml"
require_relative "scope"
require_relative "errors"

module SoftFoundry
  # How much checking a change's diff calls for, computed from the diff and
  # the globs the repository and the record declare, never judged by hand.
  # The size names and their order (smallest first) come from the policy
  # file .ai/policies/check-sizing.yml; the rules that map diff facts to a
  # size are here and are stated in that file's comments.
  #
  #   verify:  the smaller size only when the record declares a scope and
  #            every changed code path is in it (none in the shared core,
  #            none outside it); otherwise the larger.
  #   evaluate, attack:  the smaller size only when the record declares a
  #            scope, the repository declares access-control globs, and no
  #            changed path touches them; otherwise the larger.
  #
  # Absence of a declaration never reduces checking.
  class Sizing
    PHASES = %w[verify evaluate attack].freeze
    POLICY = Scope::POLICY

    # Smallest first. Used when the repository has no policy file.
    DEFAULT_SIZES = {
      "verify" => %w[targeted_plus_full_before_merge full_at_verify],
      "evaluate" => %w[touched_doors_plus_smoke full_route_sweep],
      "attack" => %w[touched_doors_plus_smoke full_route_sweep]
    }.freeze

    # `reasons` are lines "path: reason" (or a sentence when no path is
    # the cause); `base` is the commit the diff was measured from.
    Result = Data.define(:phase, :size, :applied, :base, :reasons)

    def initialize(record, git:)
      @record = record
      @plane = record.control_plane
      @git = git
      @scope = Scope.new(record, git: git)
    end

    # The size names for `phase`, smallest first.
    def sizes(phase)
      policy = self.class.policy_sizes(@plane)
      policy.fetch(phase) { raise TargetError, "check-sizing policy names no sizes for #{phase}; expected #{PHASES.join(', ')}" }
    end

    # Smallest to largest rank of a size name; nil for an unknown name.
    def rank(phase, size) = sizes(phase).index(size)

    # Sizes from the repository's policy file, or the defaults. A policy
    # that does not parse or is not a mapping of phase to size list fails
    # closed with the fix named.
    def self.policy_sizes(plane)
      file = File.join(plane.dir, "policies", "check-sizing.yml")
      return DEFAULT_SIZES unless File.file?(file)
      data = YAML.safe_load_file(file, aliases: false) || {}
      sizes = data.is_a?(Hash) ? data["sizes"] : nil
      problems = policy_problems(sizes)
      raise TargetError, "#{POLICY} is malformed: #{problems.join('; ')}; restore it from the control-plane template" unless problems.empty?
      sizes
    rescue Psych::Exception => e
      raise TargetError, "#{POLICY} is not valid YAML (#{e.message.lines.first.to_s.strip}); restore it from the control-plane template"
    end

    def self.policy_problems(sizes)
      return ["sizes must be a mapping of phase to a list of two size names, smallest first"] unless sizes.is_a?(Hash)
      PHASES.filter_map do |phase|
        list = sizes[phase]
        "sizes.#{phase} must list two distinct size names, smallest first" unless list.is_a?(Array) && list.size == 2 && list.all? { |n| n.is_a?(String) && n.match?(/\A[a-z_]+\z/) } && list.uniq.size == 2
      end
    end

    # Computes the size for `phase`. `since` is a commit to measure from;
    # by default the commit that recorded the plan. Raises TargetError
    # saying what to do when it cannot, and never answers from a failed git
    # call.
    def compute(phase, since: nil)
      raise TargetError, "unknown phase '#{phase}'; use one of: #{PHASES.join(', ')}" unless PHASES.include?(phase)
      small, large = sizes(phase)
      return Result.new(phase:, size: large, applied: Scope::WHOLE_REPOSITORY, base: since, reasons: ["no scope declared: whole-repository scope is sized at the largest size"]) unless @scope.scoped?
      base = since || @scope.change_base
      raise TargetError, "cannot size #{@record.slug}: the plan phase is not recorded as complete in a commit, so there is no diff base; pass --since <commit>" unless base
      measured = @scope.measure(base, declarations: false)
      raise TargetError, "cannot size #{@record.slug}: #{measured.error}; check the commit and branch, or pass --since <commit>" if measured.error
      phase == "verify" ? verify(small, large, base, measured) : sweep(phase, small, large, base, measured)
    end

    private

    def verify(small, large, base, measured)
      outside = measured.entries.reject { |e| e.reason == Scope::IN_SCOPE }
      return Result.new(phase: "verify", size: small, applied: measured.applied, base: base, reasons: measured.entries.map(&:to_line)) if outside.empty?
      Result.new(phase: "verify", size: large, applied: measured.applied, base: base, reasons: outside.map(&:to_line))
    end

    def sweep(phase, small, large, base, measured)
      globs = @plane.access_control
      return Result.new(phase:, size: large, applied: measured.applied, base: base, reasons: ["no access-control globs declared in .ai/repository.yml: a full sweep is the only safe size"]) if globs.empty?
      touched = measured.paths.select { |p| p.end_with?("/") ? globs.any? { |g| ControlPlane.overlaps?(p, g) } : ControlPlane.match_any?(p, globs) }
      return Result.new(phase:, size: large, applied: measured.applied, base: base, reasons: touched.map { |p| "#{p}: access control" }) unless touched.empty?
      Result.new(phase:, size: small, applied: measured.applied, base: base, reasons: ["no changed path matches the access-control globs"])
    end
  end
end
