# frozen_string_literal: true

require_relative "errors"
require_relative "gate"
require_relative "git"
require_relative "change_record"
require_relative "control_plane"
require_relative "record_file"

module SoftFoundry
  # `soft-foundry phase seal <phase>`: the one step that ends a phase.
  # Gates the phase and, when every check passes, commits the phase's
  # directory and the record's metadata in one commit the tool makes, so
  # the specification lock and the plan diff base exist because the tool
  # put them there, never because a person remembered to commit. The
  # runner calls it after a fresh session returns; a session calls it for
  # the phase it is on.
  #
  # Refusals (nothing written to git): the handoff is not complete; the
  # session's SOFT_FOUNDRY_PHASE names another phase; the checked-out
  # branch is not the record's; application, test or infrastructure code
  # is uncommitted; a record file is a symlink. A failing gate prints the
  # gate. A refused commit (the pre-commit hook, which runs `ci`, or git)
  # leaves the metadata advanced in the worktree so a rerun completes it.
  class PhaseSeal
    PHASE_ENV = "SOFT_FOUNDRY_PHASE"
    Result = Data.define(:outcome, :sha, :lines, :gate) # outcome: :sealed | :already_sealed | :refused | :gate_failed | :commit_failed

    def initialize(root, plane:, git:, record:, env: ENV)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @record = record
      @env = env
    end

    def call(phase)
      phase = @plane.phase(phase.to_s) || raise(TargetError, "unknown phase '#{phase}'; lifecycle phases: #{@plane.phases.map(&:id).join(', ')}") unless phase.is_a?(ControlPlane::Phase)
      if (why = refusal(phase))
        return Result.new(outcome: :refused, sha: nil, lines: ["#{@record.slug}: cannot seal #{phase.id}: #{why}"], gate: nil)
      end
      stamp_branch_resolved!(phase) if @plane.skill(phase.skill).commit_bound?
      gate = Gate.new(@record, git: @git).evaluate(phase)
      return Result.new(outcome: :gate_failed, sha: nil, lines: ["#{@record.slug}: #{phase.output} is not sealed: its gate fails; nothing was committed"], gate: gate) if gate.failed?
      if (sha = sealed_at(phase))
        return Result.new(outcome: :already_sealed, sha: sha, lines: ["already sealed at #{sha[0, 12]} (#{phase.output} and metadata.yml are unchanged since)"], gate: gate)
      end
      advance!(phase)
      notes = unrelated_dirty_paths(phase).first(5)
      lines = notes.empty? ? [] : ["note: left uncommitted (outside this phase and the record's metadata): #{notes.join(', ')}"]
      branch = @record.git_branch
      current = @git.branch.to_s
      if current != branch && @git.branch_tip(branch).nil?
        lines << "note: the record's branch #{branch} does not exist; this seal commits to the checked-out branch #{current.empty? ? '(detached)' : current}; create #{branch} here or correct git.branch in metadata.yml (ATK-002)"
      end
      begin
        sha = @git.commit!(message(phase), paths: staged_paths(phase))
      rescue GitError => e
        return Result.new(outcome: :commit_failed, sha: nil, lines: lines + ["#{@record.slug}: #{phase.output} is not sealed: #{e.message}", "metadata.yml is advanced in the worktree; fix the cause and run `soft-foundry phase seal #{phase.id}` again to complete the seal"], gate: gate)
      end
      Result.new(outcome: :sealed, sha: sha, lines: lines + ["sealed #{phase.output} at #{sha[0, 12]}"], gate: gate)
    end

    # The commit that already records this phase, when the phase directory
    # and metadata.yml carry no change since it; nil when a seal is due.
    def sealed_at(phase)
      sha = @record.recorded_commit(phase, git: @git)
      return nil unless sha
      dirty = @git.dirty_under("#{record_prefix}#{phase.output}/") + @git.dirty_under("#{record_prefix}metadata.yml")
      dirty.empty? ? sha : nil
    end

    private

    def record_prefix = "changes/#{@record.slug}/"

    def refusal(phase)
      return "not a git repository; a seal is a commit" unless @git.repository?
      begin
        handoff = @record.handoff(phase)
        branch = @record.git_branch
      rescue TargetError => e
        return e.message
      end
      return "#{phase.output}/handoff.yml is missing" unless handoff
      status = handoff["status"].to_s
      return "#{phase.output}/handoff.yml says status #{status.empty? ? '(none)' : status}; set it complete (with commit_sha, completed_at, and outputs) when the phase's work is done, then seal" unless status == "complete"
      session = @env[PHASE_ENV].to_s
      unless session.empty? || session == phase.id
        return "this session is running #{session}, so it may seal only #{session}; a phase is sealed by the session that did its work or by the runner"
      end
      current = @git.branch.to_s
      if current != branch && @git.branch_tip(branch)
        return "the checked-out branch is #{current.empty? ? '(detached)' : current}, not the record's #{branch}; check out #{branch} (or its worktree) to seal"
      end
      code = @git.code_dirty_paths(@plane.code_globs)
      unless code.empty?
        return "uncommitted application, test, or infrastructure paths: #{code.first(5).join(', ')}#{code.size > 5 ? " (and #{code.size - 5} more)" : ''}; commit the code first, since commit_sha describes committed code"
      end
      nil
    rescue GitError => e
      e.message
    end

    # Whether metadata.git.branch resolved when this evidence was sealed:
    # the measure `Scope.tip_for` needs later (REQ-020).
    def stamp_branch_resolved!(phase)
      resolved = !@git.branch_tip(@record.git_branch).nil?
      @record.update_handoff(phase) { |h| h["branch_resolved"] = resolved }
    end

    # The next phase a session should work on: the first later one that is
    # not complete, stepping over a pending phase that is waived, optional,
    # or track-optional (an in-progress or blocked one counts); unchanged
    # when none. A first seal moves the change out of intake; sealing
    # judgment marks it judged.
    def advance!(phase)
      later = @plane.phases.drop(@plane.phases.index(phase) + 1)
      nxt = later.find { |p| @record.phase_status(p) != "complete" && !(@record.phase_status(p) == "pending" && @record.skippable?(p)) }
      @record.update_metadata do |m|
        m["status"] = "in_progress" if m["status"].to_s == "intake"
        m["status"] = "judged" if phase.id == "judge"
        m["current_phase"] = nxt.id if nxt
      end
    end

    def staged_paths(phase)
      paths = ["#{record_prefix}#{phase.output}", "#{record_prefix}metadata.yml"]
      budget = "#{record_prefix}budget.yml"
      paths << budget unless @git.dirty_under(budget).empty?
      paths
    end

    def unrelated_dirty_paths(phase)
      own = staged_paths(phase)
      @git.dirty_paths.reject { |p| own.any? { |o| p == o || p.start_with?("#{o}/") } || p.end_with?("/") && own.any? { |o| o.start_with?(p) } }
    end

    def message(phase) = "Record #{@record.slug} #{phase.id}"
  end
end
