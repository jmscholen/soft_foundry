# frozen_string_literal: true

module SoftFoundry
  # Deterministic completion gate for one lifecycle phase of a change record.
  # Pending phases are skipped; complete phases must satisfy completion.yml,
  # carry a valid handoff, and (when commit-bound) not be stale.
  class Gate
    Check = Data.define(:name, :outcome, :detail) # outcome: :pass | :fail | :warn | :skip
    Result = Data.define(:phase, :status, :checks) do
      def failed? = checks.any? { |c| c.outcome == :fail }
      def stale? = checks.any? { |c| c.name == "evidence current" && c.outcome == :fail }
      def skipped? = checks.all? { |c| c.outcome == :skip }
    end

    SHA = /\A[0-9a-f]{7,40}\z/
    PLACEHOLDER = /\bTBD\b/

    def initialize(record, git: Git.new(record.root))
      @record = record
      @plane = record.control_plane
      @git = git
    end

    def evaluate_all
      @plane.phases.map { |phase| evaluate(phase) }
    end

    def evaluate(phase)
      phase = @plane.phase(phase) || raise(ArgumentError, "unknown phase '#{phase}'") unless phase.is_a?(ControlPlane::Phase)
      skill = @plane.skill(phase.skill)
      checks = []
      handoff = @record.handoff(phase)
      return Result.new(phase:, status: "missing", checks: [Check.new("handoff present", :fail, "#{phase.output}/handoff.yml is missing")]) unless handoff

      status = handoff["status"].to_s
      unless ChangeRecord::STATUSES.include?(status)
        return Result.new(phase:, status:, checks: [Check.new("handoff status", :fail, "status '#{status}' is not one of #{ChangeRecord::STATUSES.join(', ')}")])
      end
      return Result.new(phase:, status:, checks: [Check.new("phase pending", :skip, "not started")]) if status == "pending"

      checks << identity_check(phase, skill, handoff)
      blocking = Array(handoff["blocking"])

      case status
      when "in_progress"
        checks << Check.new("phase in progress", :warn, "not yet gated")
      when "blocked"
        checks << (blocking.empty? ? Check.new("blocking recorded", :fail, "status is blocked but `blocking` is empty") : Check.new("blocking recorded", :warn, blocking.join("; ")))
      when "complete"
        checks << required_files_check(phase, skill)
        checks << placeholder_check(phase, skill)
        checks << (blocking.empty? ? Check.new("no blocking conditions", :pass, "") : Check.new("no blocking conditions", :fail, "complete with unresolved: #{blocking.join('; ')}"))
        checks << commit_check(handoff)
        checks << Check.new("completed_at recorded", handoff["completed_at"] ? :pass : :fail, handoff["completed_at"].to_s)
        checks << predecessor_check(phase)
        checks << staleness_check(handoff) if skill.commit_bound?
      end
      Result.new(phase:, status:, checks:)
    end

    private

    def identity_check(phase, skill, handoff)
      problems = []
      problems << "phase is '#{handoff['phase']}', expected '#{phase.output}'" unless handoff["phase"] == phase.output
      problems << "skill is '#{handoff['skill']}', expected '#{skill.name}'" unless handoff["skill"] == skill.name
      problems.empty? ? Check.new("handoff identity", :pass, "") : Check.new("handoff identity", :fail, problems.join("; "))
    end

    def required_files_check(phase, skill)
      missing = skill.required_files.reject { |f| File.exist?(File.join(@record.phase_dir(phase), f)) }
      missing.empty? ? Check.new("required files present", :pass, skill.required_files.join(", ")) : Check.new("required files present", :fail, "missing: #{missing.join(', ')}")
    end

    def placeholder_check(phase, skill)
      remaining = skill.required_files.select do |f|
        path = File.join(@record.phase_dir(phase), f)
        File.file?(path) && File.read(path).match?(PLACEHOLDER)
      end
      remaining.empty? ? Check.new("no placeholders", :pass, "") : Check.new("no placeholders", :fail, "TBD remains in: #{remaining.join(', ')}")
    end

    def commit_check(handoff)
      sha = handoff["commit_sha"].to_s
      return Check.new("commit_sha recorded", :fail, "missing or malformed") unless sha.match?(SHA)
      return Check.new("commit_sha recorded", :fail, "#{sha} is not a commit in this repository") if @git.repository? && !@git.commit?(sha)
      Check.new("commit_sha recorded", :pass, sha)
    end

    # Remediation is the workflow's loop target: it may close while an earlier
    # gated phase is blocked, because that blockage is what it repairs.
    def predecessor_check(phase)
      prev = @plane.predecessor(phase)
      return Check.new("predecessor complete", :pass, "first phase") unless prev
      if phase.id == "remediate"
        blocked = @plane.phases.select { |p| @record.phase_status(p) == "blocked" }
        return Check.new("predecessor complete", :pass, "repairing blocked #{blocked.map(&:output).join(', ')}") unless blocked.empty?
      end
      prev_status = @record.phase_status(prev)
      prev_status == "complete" ? Check.new("predecessor complete", :pass, prev.output) : Check.new("predecessor complete", :fail, "#{prev.output} is #{prev_status || 'missing'}")
    end

    def staleness_check(handoff)
      sha = handoff["commit_sha"].to_s
      return Check.new("evidence current", :skip, "no git repository") unless @git.repository?
      return Check.new("evidence current", :fail, "cannot compare: commit_sha invalid") unless sha.match?(SHA) && @git.commit?(sha)
      changed = @git.changed_since(sha).select { |p| ControlPlane.match_any?(p, @plane.code_globs) }
      changed.empty? ? Check.new("evidence current", :pass, "no code changes since #{sha[0, 12]}") : Check.new("evidence current", :fail, "STALE: code changed since #{sha[0, 12]}: #{changed.first(5).join(', ')}#{changed.size > 5 ? ' …' : ''}")
    end
  end
end
