# frozen_string_literal: true

require "yaml"
require "date"
require_relative "learning"

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
      checks << track_check if @plane.phases.first == phase
      blocking = Array(handoff["blocking"])

      case status
      when "in_progress"
        checks << Check.new("phase in progress", :warn, "not yet gated")
      when "blocked"
        checks << (blocking.empty? ? Check.new("blocking recorded", :fail, "status is blocked but `blocking` is empty") : Check.new("blocking recorded", :warn, blocking.join("; ")))
      when "complete"
        checks << exploring_check if @record.exploring? && @plane.hardening_phase?(phase)
        checks << required_files_check(phase, skill)
        checks << placeholder_check(phase, skill)
        checks << (blocking.empty? ? Check.new("no blocking conditions", :pass, "") : Check.new("no blocking conditions", :fail, "complete with unresolved: #{blocking.join('; ')}"))
        checks << commit_check(handoff)
        checks << Check.new("completed_at recorded", handoff["completed_at"] ? :pass : :fail, handoff["completed_at"].to_s)
        checks << predecessor_check(phase)
        checks << staleness_check(handoff) if skill.commit_bound?
        checks << specification_lock_check(phase) if phase.id == "specify" && @record.vetted
        checks << red_evidence_check(phase, handoff) if phase.id == "verify"
        checks << instincts_check if phase.id == "learn"
      end
      Result.new(phase:, status:, checks:)
    end

    private

    # The change's track must exist, must have an exploring stage if the
    # change is exploring, and must be the one its declared risk forces.
    # Reported once, on the first phase, so `status`/`ci` show it whenever
    # any work has started.
    def track_check
      name = @record.track
      definition = @record.track_definition
      return Check.new("track permitted", :fail, "track '#{name}' is not defined in .ai/workflow.yml (#{@plane.track_names.join(', ')})") unless definition
      if @record.exploring? && !definition.exploring?
        return Check.new("track permitted", :fail, "status is exploring but track '#{name}' has no exploring stage")
      end
      risk = @record.metadata["risk"].to_s
      forced = @plane.track_forced_by_risk(risk)
      if forced && forced != name
        return Check.new("track permitted", :fail, "risk #{risk} forces the #{forced} track (.ai/workflow.yml tracks.forced_by_risk) but the change is on #{name}")
      end
      Check.new("track permitted", :pass, name)
    end

    # The exploring stage produces a journal, never evidence: nothing from
    # implement onward may be complete until the person has vetted.
    def exploring_check
      Check.new("not exploring", :fail, "cannot be complete while the change is exploring; run `soft-foundry change vet` when the person has accepted the feature, then rerun this phase")
    end

    # The learning phase's instincts must be well-formed to be promotable:
    # kebab-case unique ids, a trigger and an action, a confidence in 0..1,
    # and evidence in this record. An empty list is a valid answer.
    def instincts_check
      instincts, problems = Learning.read(@record)
      return Check.new("instincts valid", :fail, problems.join("; ")) unless problems.empty?
      return Check.new("instincts valid", :pass, "no instincts recorded") if instincts.empty?
      Check.new("instincts valid", :pass, "#{instincts.size} #{instincts.size == 1 ? 'instinct' : 'instincts'}: #{instincts.map(&:id).join(', ')}")
    end

    # A verification check may name the commit at which its test existed
    # and failed (red_commit) and the test file (test_path). The gate
    # checks the shape of that claim: the commit exists, precedes the
    # verified commit, holds the test file, and code changed after it.
    # Whether the test actually failed there is not re-run; the claim is
    # the agent's, bound to a commit anyone can check out.
    def red_evidence_check(phase, handoff)
      path = File.join(@record.phase_dir(phase), "tests.yml")
      return Check.new("red evidence", :skip, "tests.yml missing") unless File.file?(path)
      data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
      checks = Array(data["checks"]).select { |c| c.is_a?(Hash) && c.key?("red_commit") }
      return Check.new("red evidence", :skip, "no check records a red_commit") if checks.empty?
      return Check.new("red evidence", :skip, "no git repository") unless @git.repository?
      green = handoff["commit_sha"].to_s
      problems = []
      passes = []
      checks.each do |c|
        id = c["id"].to_s
        red = c["red_commit"].to_s
        test_path = c["test_path"].to_s
        next problems << "#{id}: red_commit '#{red}' is not a commit in this repository" unless red.match?(SHA) && @git.commit?(red)
        next problems << "#{id}: red_commit #{red[0, 12]} is the verified commit itself; the test must precede the implementation" if green.start_with?(red) || red.start_with?(green)
        next problems << "#{id}: red_commit #{red[0, 12]} is not an ancestor of the verified commit #{green[0, 12]}" unless @git.ancestor?(red, green)
        next problems << "#{id}: test_path #{test_path} does not exist at red_commit #{red[0, 12]}" if !test_path.empty? && !@git.file_at?(red, test_path)
        code = @git.changed_between(red, green).select { |p| ControlPlane.match_any?(p, %w[APP INFRA].flat_map { |g| @plane.path_groups.fetch(g, []) }) }
        next problems << "#{id}: no APP or INFRA change between red_commit #{red[0, 12]} and #{green[0, 12]}; nothing was implemented after the test" if code.empty?
        passes << "#{id}: #{red[0, 12]} -> #{green[0, 12]}#{test_path.empty? ? '' : " (#{test_path})"}"
      end
      return Check.new("red evidence", :fail, problems.join("; ")) unless problems.empty?
      Check.new("red evidence", :pass, passes.join("; "))
    rescue Psych::Exception => e
      Check.new("red evidence", :fail, "tests.yml is not valid YAML: #{e.message}")
    end

    # After `change vet`, the specification is what the hardening phases
    # are checked against, so it may not change; reshaping the feature
    # goes through `change reopen`. Deterministic acceptance-criteria
    # locking for the iterative track.
    def specification_lock_check(phase)
      sha = @record.vetted["commit"].to_s
      return Check.new("specification locked", :skip, "no git repository") unless @git.repository?
      return Check.new("specification locked", :fail, "vetted commit '#{sha}' is not a commit in this repository") unless sha.match?(SHA) && @git.commit?(sha)
      prefix = "changes/#{@record.slug}/#{phase.output}/"
      changed = @git.changed_since(sha).select { |p| p.start_with?(prefix) }
      return Check.new("specification locked", :pass, "unchanged since vet at #{sha[0, 12]}") if changed.empty?
      Check.new("specification locked", :fail, "changed since vet at #{sha[0, 12]}: #{changed.first(5).join(', ')}#{changed.size > 5 ? ' …' : ''}; run `soft-foundry change reopen` to reshape the feature")
    end

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

    # Honors `after` overrides, globally optional phases, a change's own
    # skipped_phases (each requiring a non-empty rationale), and phases the
    # change's track does not require.
    def predecessor_check(phase)
      prev = @plane.effective_predecessor(phase, skip: ->(p) { @record.skippable?(p) }) { |p| @record.phase_status(p) }
      return Check.new("predecessor complete", :pass, "first phase") unless prev
      prev_status = @record.phase_status(prev)
      prev_status == "complete" ? Check.new("predecessor complete", :pass, prev.output) : Check.new("predecessor complete", :fail, "#{prev.output} is #{prev_status || 'missing'}")
    end

    # Evidence is stale when code changed after the commit it describes.
    # "After" is measured on the record's own branch when that branch
    # exists and is not the one checked out: a change stacked on another
    # change's branch covers its own code with its own record, and the
    # earlier record's claim is about the earlier branch. On the record's
    # branch itself (or when its branch is gone) the worktree is the
    # measure, uncommitted edits included, exactly as before.
    def staleness_check(handoff)
      sha = handoff["commit_sha"].to_s
      return Check.new("evidence current", :skip, "no git repository") unless @git.repository?
      return Check.new("evidence current", :fail, "cannot compare: commit_sha invalid") unless sha.match?(SHA) && @git.commit?(sha)
      record_branch = @record.metadata.dig("git", "branch").to_s
      tip = record_branch != @git.branch.to_s ? @git.branch_tip(record_branch) : nil
      changed = (tip ? @git.changed_between(sha, tip) : @git.changed_since(sha)).select { |p| ControlPlane.match_any?(p, @plane.code_globs) }
      where = tip ? " on branch #{record_branch}" : ""
      return Check.new("evidence current", :pass, "no code changes since #{sha[0, 12]}#{where}") if changed.empty?
      Check.new("evidence current", :fail, "STALE: code changed since #{sha[0, 12]}#{where}: #{changed.first(5).join(', ')}#{changed.size > 5 ? ' …' : ''}")
    end
  end
end
