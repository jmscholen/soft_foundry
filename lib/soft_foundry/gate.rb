# frozen_string_literal: true

require "yaml"
require "date"
require_relative "text"
require_relative "change_record"
require_relative "learning"
require_relative "panel"
require_relative "content_scan"
require_relative "scope"
require_relative "sizing"
require_relative "full_suite"

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
    SIZE_CHECK = "check size matches diff"
    PROTECTION_CHECK = "protection stated"
    PROTECTION_VALUES = %w[in_force disabled not_applicable].freeze
    FULL_SUITE_CHECK = "full-suite run recorded (record check, not a test result)"
    PLACEHOLDER = /\bTBD\b/

    # What each check establishes, for anything that explains a gate to a
    # person. Keyed by the name `evaluate` reports.
    CHECKS = {
      "handoff present" => "The phase directory has a handoff.yml.",
      "handoff status" => "The handoff's status is one of #{ChangeRecord::STATUSES.join(', ')}.",
      "phase pending" => "The phase has not started, so there is nothing to gate.",
      "phase in progress" => "The phase is being worked on and is not gated until it is complete.",
      "blocking recorded" => "A blocked phase names what is blocking it.",
      "handoff identity" => "The handoff names this phase and the skill the workflow assigns to it.",
      "track permitted" => "The change's track is defined, has an exploring stage if the change is exploring, and is the one its risk forces.",
      "waivers permitted" => "Every phase in skipped_phases is optional or one the change's declared risk may waive (.ai/workflow.yml waivable_by_risk); review and judgment are never waived.",
      "not exploring" => "No phase from implementation onward is complete while the change is still exploring.",
      "required files present" => "Every file the skill's completion.yml requires exists.",
      "no placeholders" => "No required file still contains a TBD placeholder.",
      "no blocking conditions" => "The handoff lists no unresolved blocking condition.",
      "commit_sha recorded" => "The handoff is bound to a commit that exists in this repository.",
      "completed_at recorded" => "The handoff records when the phase was completed.",
      "predecessor complete" => "The phase before this one is complete (optional, waived, and track-optional phases are stepped over).",
      "evidence current" => "No application, test, or infrastructure code changed after the commit this evidence describes, and the specification was not re-recorded after it.",
      "specification locked" => "The specification is unchanged since it was recorded (the commit that recorded the completed phase, or the vetted commit on an iterative change).",
      "red evidence" => "Each test named with a red_commit existed before the implementation and code changed after it.",
      SIZE_CHECK => "The check size recorded in tests.yml is not smaller than the size computed from the diff and the declared scope, shared core and access-control globs.",
      PROTECTION_CHECK => "When the repository profile declares access_control and a changed path matches, tests.yml states the protection of its checks: one check in_force, or every check states a value with a note. Presence only; whether a claim is true is for review.",
      FULL_SUITE_CHECK => "A full-suite run recorded in tests.yml (or cited from another record) names the tree of the evidence commit, with a recorded outcome of passed. A record check: Soft Foundry never runs the suite, and a pass here is not a test result.",
      "instincts valid" => "The instincts the learning phase recorded are well formed.",
      "findings explained" => "Every review finding above minor names the failure it prevents.",
      "panel recorded" => "A phase run as a panel has a draft per member, a non-empty ARGUMENT.md, an outcome, and every draft cited in its outputs.",
      "content clean" => "The phase's files carry no invisible text or secret-shaped strings."
    }.freeze

    # The checks a complete `phase` is put through, in the order `evaluate`
    # runs them. Checks that depend on the change's own state (exploring,
    # vetted) are listed where they can apply.
    def self.checks_for(plane, phase)
      names = ["handoff identity"]
      names << "track permitted" if plane.phases.first == phase
      names << "waivers permitted" if plane.phases.first == phase
      names << "not exploring" if plane.hardening_phase?(phase)
      names += ["required files present", "no placeholders", "no blocking conditions", "commit_sha recorded", "completed_at recorded", "predecessor complete"]
      names << "evidence current" if plane.skill(phase.skill).commit_bound?
      names << "specification locked" if phase.id == "specify"
      names += ["red evidence", SIZE_CHECK, PROTECTION_CHECK, FULL_SUITE_CHECK] if phase.id == "verify"
      names << "instincts valid" if phase.id == "learn"
      names << "findings explained" if phase.id == "review"
      names << "panel recorded" if plane.panel_phases.include?(phase)
      names << "content clean"
    end

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
      checks << waivers_check if @plane.phases.first == phase
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
        checks << staleness_check(phase, handoff) if skill.commit_bound?
        checks << specification_lock_check(phase) if phase.id == "specify"
        checks << red_evidence_check(phase, handoff) if phase.id == "verify"
        checks.concat(scoped_verification_checks(phase, handoff)) if phase.id == "verify"
        checks << protection_check(phase) if phase.id == "verify"
        checks << instincts_check if phase.id == "learn"
        checks << findings_explained_check(handoff) if phase.id == "review"
        checks << panel_check(phase, handoff) if handoff["panel"].is_a?(Hash)
        checks << content_check(phase)
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

    # What a change may waive is decided by its declared risk, not by the
    # rationale: skipped_phases may name a globally optional phase, or one
    # .ai/workflow.yml waivable_by_risk lists for the risk; review and
    # judgment never. Reported on the first phase, like the track, so it
    # shows whenever any work has started. Structure only: the rationale
    # text is not judged.
    def waivers_check
      risk = @record.metadata["risk"].to_s.strip
      classified = !risk.empty? && !risk.match?(PLACEHOLDER)
      allowed = @plane.waivable_by_risk(risk)
      problems = Array(@record.metadata["skipped_phases"]).filter_map do |entry|
        next unless entry.is_a?(Hash)
        id = entry["phase"].to_s
        phase = @plane.phase(id)
        next "'#{id}' is not a lifecycle phase" unless phase
        next "#{id} is never waived (review and judgment are required of every change)" if ControlPlane::NEVER_WAIVED.include?(phase.id)
        next if phase.optional || allowed.include?(phase.id)
        next "#{id} cannot be waived until the risk is classified (metadata.yml risk: #{risk.empty? ? 'unset' : risk})" unless classified
        "#{id} cannot be waived at risk #{risk.downcase} (waivable: #{allowed.empty? ? 'none' : allowed.join(', ')}; .ai/workflow.yml waivable_by_risk)"
      end
      return Check.new("waivers permitted", :pass, Array(@record.metadata["skipped_phases"]).empty? ? "nothing waived" : "risk #{risk.downcase}") if problems.empty?
      Check.new("waivers permitted", :fail, problems.join("; "))
    end

    # The exploring stage produces a journal, never evidence: nothing from
    # implement onward may be complete until the person has vetted.
    def exploring_check
      Check.new("not exploring", :fail, "cannot be complete while the change is exploring; run `soft-foundry change vet` when the person has accepted the feature, then rerun this phase")
    end

    # A completed phase's files are what later phases and people read.
    # Invisible text and secret-shaped strings fail the phase; an
    # override phrase or fetch-and-execute command is a warning, since a
    # record may quote an attack it found.
    def content_check(phase)
      findings = ContentScan.scan_paths(@record.root, ContentScan.phase_paths(@record.root, @record, phase))
      return Check.new("content clean", :pass, "") if findings.empty?
      describe = ->(f) { "#{File.basename(f.path)}:#{f.line} #{f.kind} (#{f.detail})" }
      errors = findings.select { |f| f.level == :error }
      return Check.new("content clean", :fail, errors.first(4).map(&describe).join("; ") + (errors.size > 4 ? " …" : "")) unless errors.empty?
      Check.new("content clean", :warn, findings.first(4).map(&describe).join("; ") + (findings.size > 4 ? " …" : ""))
    end

    # A review's findings must say what failure they prevent (`failure:`
    # in the handoff), except minor ones. Any other severity word, or none,
    # counts as serious, so a finding cannot skip the check by being called
    # critical. Structure only: the gate checks the field is there and not
    # empty, never that the failure is real.
    UNEXPLAINED_OK = %w[minor].freeze

    def findings_explained_check(handoff)
      findings = Array(handoff["findings"]).select { |f| f.is_a?(Hash) && !UNEXPLAINED_OK.include?(f["severity"].to_s.strip.downcase) }
      return Check.new("findings explained", :pass, "no findings above minor") if findings.empty?
      missing = findings.select { |f| f["failure"].to_s.strip.empty? }.map { |f| f["id"] || "(no id)" }
      return Check.new("findings explained", :fail, "no failure: on #{missing.join(', ')}; every finding above minor names the concrete input or state and the wrong result it leads to, or it is minor") unless missing.empty?
      Check.new("findings explained", :pass, "#{findings.size} #{findings.size == 1 ? 'finding above minor names its' : 'findings above minor name their'} failure")
    end

    # A phase run as a panel (`panel:` in its handoff, written by the
    # runner) must show the panel's work: a draft per member, the
    # argument, an outcome, and the drafts cited in the phase's outputs.
    # Structure only, like every gate check.
    def panel_check(phase, handoff)
      panel = handoff["panel"]
      dir = @record.phase_dir(phase)
      members = Array(panel["members"]).filter_map { |m| m["name"].to_s if m.is_a?(Hash) }.select { |n| n.match?(Panel::NAME) }
      problems = []
      problems << "fewer than two members recorded" if members.size < 2
      members.each do |name|
        folder = File.join(dir, "panel", name)
        problems << "panel/#{name}/ has no draft" unless File.directory?(folder) && Dir.glob("**/*", base: folder).any? { |f| File.file?(File.join(folder, f)) && File.size(File.join(folder, f)).positive? }
      end
      argument = File.join(dir, "panel", "ARGUMENT.md")
      problems << "panel/ARGUMENT.md is missing" unless File.file?(argument)
      problems << "panel/ARGUMENT.md is empty" if File.file?(argument) && SoftFoundry.read_text(argument).strip.empty?
      problems << "outcome is '#{panel['outcome']}', not agreed or split" unless %w[agreed split].include?(panel["outcome"].to_s)
      outputs = Dir.glob("**/*", base: dir).reject { |f| f.start_with?("panel/") || f == "handoff.yml" }.map { |f| File.join(dir, f) }.select { |f| File.file?(f) }
      text = outputs.map { |f| SoftFoundry.read_text(f) }.join("\n")
      members.each { |name| problems << "panel/#{name}/ is not cited in the phase's outputs" unless text.include?("panel/#{name}/") }
      return Check.new("panel recorded", :fail, problems.join("; ")) unless problems.empty?
      Check.new("panel recorded", :pass, "#{members.size} members, #{panel['rounds']} #{panel['rounds'].to_i == 1 ? 'round' : 'rounds'}, #{panel['outcome']}")
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

    # The specification is what every later phase is checked against, so
    # once recorded it may not change. On a vetted (iterative) change the
    # lock is the vetted commit and reshaping goes through `change reopen`.
    # On every other track the lock is the commit that recorded the
    # completed specification (the newest commit touching its handoff
    # while that handoff says complete); a later change under
    # 02-specification/ is a recorded requirement change, made by rerunning
    # the phase, after which every commit-bound phase is stale (see
    # staleness_check). Until the completed handoff is committed there is
    # nothing to lock to, and the check says so without failing.
    def specification_lock_check(phase)
      return vetted_lock_check(phase) if @record.vetted
      return Check.new("specification locked", :skip, "no git repository") unless @git.repository?
      lock = specification_lock_commit(phase)
      unless lock
        return Check.new("specification locked", :warn, "not yet locked: the completed specification is not committed; the lock takes effect at the commit that records #{phase.output}/handoff.yml as complete")
      end
      prefix = "changes/#{@record.slug}/#{phase.output}/"
      changed = @git.changed_since(lock).select { |p| p.start_with?(prefix) && p != "#{prefix}handoff.yml" }
      return Check.new("specification locked", :pass, "locked at #{lock[0, 12]}, the commit that recorded it") if changed.empty?
      Check.new("specification locked", :fail, "changed since the specification was recorded at #{lock[0, 12]}: #{changed.first(5).join(', ')}#{changed.size > 5 ? ' …' : ''}; a specification change after the lock is a recorded requirement change: rerun the specification phase (its handoff re-binds the lock), after which every commit-bound phase is stale and must be redone against the new criteria")
    end

    # The commit that recorded the completed specification, or nil when
    # the phase is not complete or its completed handoff is not committed.
    def specification_lock_commit(phase = @plane.phase("specify"))
      phase ? recorded_commit(phase) : nil
    end

    # The commit that recorded a phase as complete, or nil (see
    # ChangeRecord#recorded_commit).
    def recorded_commit(phase) = @record.recorded_commit(phase, git: @git)

    def vetted_lock_check(phase)
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
        File.file?(path) && SoftFoundry.read_text(path).match?(PLACEHOLDER)
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
    #
    # Evidence is also stale when the specification was re-recorded after
    # it: the criteria it was checked against are no longer the criteria.
    # "After" is the order of the commits that recorded the two handoffs
    # (the specification's lock commit and this phase's handoff commit);
    # recorded in the same commit, or this phase recorded later, is current.
    def staleness_check(phase, handoff)
      sha = handoff["commit_sha"].to_s
      return Check.new("evidence current", :skip, "no git repository") unless @git.repository?
      return Check.new("evidence current", :fail, "cannot compare: commit_sha invalid") unless sha.match?(SHA) && @git.commit?(sha)
      tip = Scope.tip_for(@record, @git, sha)
      record_branch = @record.metadata.dig("git", "branch").to_s
      where = tip ? " on branch #{record_branch}" : ""
      scope = Scope.new(@record, git: @git)
      scope_note = ""
      if tip && !@git.ancestor?(sha, tip)
        return Check.new("evidence current", :fail, "STALE: branch #{record_branch} does not contain the evidence commit #{sha[0, 12]}; correct git.branch in metadata.yml")
      end
      if !scope.scoped? && (edit = Scope.branch_edit(@record, @git, sha))
        return Check.new("evidence current", :fail, "STALE: #{edit} since #{sha[0, 12]}; rerun this phase")
      end
      if scope.scoped?
        measured = scope.measure(sha)
        return Check.new("evidence current", :fail, scoped_stale_detail(sha, measured)) if measured.stale?
        scope_note = "\nscope: #{measured.applied}"
      else
        changed = (tip ? @git.changed_between(sha, tip) : @git.changed_since(sha)).select { |p| ControlPlane.match_any?(p, @plane.code_globs) }
        unless changed.empty?
          return Check.new("evidence current", :fail, "STALE: code changed since #{sha[0, 12]}#{where}: #{changed.first(5).join(', ')}#{changed.size > 5 ? ' …' : ''}")
        end
      end
      lock = @record.vetted ? nil : specification_lock_commit
      own = lock && recorded_commit(phase)
      if lock && own && !@git.ancestor?(lock, own)
        return Check.new("evidence current", :fail, "STALE: the specification was re-recorded at #{lock[0, 12]} after this evidence (handoff recorded at #{own[0, 12]}); rerun this phase against the current criteria")
      end
      Check.new("evidence current", :pass, "no code changes since #{sha[0, 12]}#{where}#{lock ? "; specification unchanged since #{lock[0, 12]}" : ''}#{scope_note}")
    end

    # The stale detail for a scoped record: the cause on the first line,
    # then one fact per line (the applied scope, and each causing path with
    # its reason), so each can be found by its prefix.
    def scoped_stale_detail(sha, measured)
      return "STALE: cannot tell what changed since #{sha[0, 12]}: #{measured.error}; check the commit and branch\nscope: #{measured.applied}" if measured.error
      paths = measured.reasons.map(&:path)
      head = "STALE: code changed since #{sha[0, 12]}#{measured.where} for this scope: #{paths.first(5).join(', ')}#{paths.size > 5 ? ' (and more)' : ''}"
      ([head, "scope: #{measured.applied}"] + measured.reasons.map { |e| "reason: #{e.to_line}" }).join("\n")
    end

    # The two checks scoped verification adds to verification: the recorded
    # size against the size computed from the diff, and the recorded full
    # suite run. An unscoped record is whole-repository: nothing is asked
    # of it unless it records a run, which is then checked like any other.
    def scoped_verification_checks(phase, handoff)
      scope = Scope.new(@record, git: @git)
      tests = tests_yml(phase)
      block = tests.is_a?(Hash) ? tests["full_suite"] : nil
      return [Check.new(SIZE_CHECK, :skip, "no git repository"), full_suite_check(handoff, block, nil, false)] unless @git.repository?
      unless scope.scoped?
        return [Check.new(SIZE_CHECK, :skip, "no scope declared: the whole repository is sized at the largest size"), full_suite_check(handoff, block, nil, false)]
      end
      computed, size_check = computed_size_check(tests)
      [size_check, full_suite_check(handoff, block, computed, true)]
    end

    # Access-control parity (.ai/rules/access-control-parity.md). Applies
    # only when the profile declares `access_control` and a path changed
    # since the plan matches one of its globs; otherwise it is skipped and
    # the record is unaffected. Structure only: a `protection: in_force`
    # claim is not checked against the run.
    def protection_check(phase)
      raw = @plane.repository_profile["access_control"]
      return Check.new(PROTECTION_CHECK, :skip, "the repository profile declares no access_control") if raw.nil? || raw == []
      problems = access_control_problems(raw)
      return Check.new(PROTECTION_CHECK, :fail, ".ai/repository.yml: #{problems.join('; ')}") unless problems.empty?
      return Check.new(PROTECTION_CHECK, :skip, "no git repository") unless @git.repository?
      scope = Scope.new(@record, git: @git)
      base = scope.change_base
      return Check.new(PROTECTION_CHECK, :fail, "access_control is declared but the plan phase is not recorded in a commit, so the changed paths cannot be found") unless base
      measured = scope.measure(base, declarations: false)
      return Check.new(PROTECTION_CHECK, :fail, "cannot list the changed paths: #{measured.error}") if measured.error
      touched = measured.paths.select { |path| ControlPlane.match_any?(path, @plane.access_control) }
      return Check.new(PROTECTION_CHECK, :skip, "no changed path matches the access_control globs") if touched.empty?
      protection_findings(tests_yml(phase), touched)
    end

    # Why the declared globs cannot be read: the shape rules `check` applies,
    # plus unbalanced brackets or braces, which never match anything.
    def access_control_problems(raw)
      return ["access_control must be a list of path globs"] unless raw.is_a?(Array)
      raw.flat_map do |glob|
        found = Declarations.syntax_problems(glob, :access_control)
        next found unless found.empty?
        balanced = glob.count("[") == glob.count("]") && glob.count("{") == glob.count("}")
        balanced ? [] : ["access_control glob #{glob.dump} has an unclosed [ or {; fix the glob"]
      end
    end

    def protection_findings(tests, touched)
      where = "changed access-control path#{touched.size == 1 ? '' : 's'}: #{touched.first(3).join(', ')}#{touched.size > 3 ? ", and #{touched.size - 3} more" : ''}"
      checks = tests.is_a?(Hash) && tests["checks"].is_a?(Array) ? tests["checks"].select { |c| c.is_a?(Hash) } : []
      fix = "set `protection: in_force` on a check run with the protection enabled, or give every check a `protection` (#{PROTECTION_VALUES.join(' | ')}) and a `protection_note`"
      return Check.new(PROTECTION_CHECK, :fail, "#{where}; tests.yml lists no checks; #{fix}") if checks.empty?
      name = ->(c) { c["id"].to_s.empty? ? "(unnamed check)" : c["id"].to_s }
      invalid = checks.select { |c| c.key?("protection") && !PROTECTION_VALUES.include?(c["protection"].to_s) }
      return Check.new(PROTECTION_CHECK, :fail, "#{where}; #{invalid.map(&name).join(', ')} has a protection that is not one of #{PROTECTION_VALUES.join(', ')}") unless invalid.empty?
      note = ->(c) { !c["protection_note"].to_s.strip.empty? }
      bare = checks.select { |c| c["protection"].to_s == "disabled" && !note.call(c) }
      return Check.new(PROTECTION_CHECK, :fail, "#{where}; #{bare.map(&name).join(', ')} states protection: disabled without a protection_note saying why") unless bare.empty?
      return Check.new(PROTECTION_CHECK, :pass, "#{where}; #{checks.count { |c| c['protection'].to_s == 'in_force' }} check(s) in force") if checks.any? { |c| c["protection"].to_s == "in_force" }
      unstated = checks.reject { |c| c.key?("protection") && note.call(c) }
      return Check.new(PROTECTION_CHECK, :fail, "#{where}; no check states protection: in_force and #{unstated.map(&name).join(', ')} gives no protection with a note; #{fix}") unless unstated.empty?
      Check.new(PROTECTION_CHECK, :pass, "#{where}; every check states its protection with a note")
    end

    def tests_yml(phase)
      path = File.join(@record.phase_dir(phase), "tests.yml")
      return nil unless File.file?(path)
      YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
    rescue Psych::Exception
      nil
    end

    # [computed Sizing::Result or nil, the size check].
    def computed_size_check(tests)
      sizing = Sizing.new(@record, git: @git)
      computed = sizing.compute("verify")
      recorded = tests.is_a?(Hash) ? tests["size"].to_s : ""
      because = computed.reasons.first(3).join("; ")
      because = "no changed code path is the cause; the diff base or a declaration is" if because.empty?
      if recorded.empty?
        return [computed, Check.new(SIZE_CHECK, :fail, "no size is recorded in tests.yml; computed size is #{computed.size} (#{because}); record `size: #{computed.size}` and run those checks")]
      end
      recorded_rank = sizing.rank("verify", recorded)
      unless recorded_rank
        return [computed, Check.new(SIZE_CHECK, :fail, "recorded size '#{recorded}' is not one of #{sizing.sizes('verify').join(', ')}; record the computed size #{computed.size}")]
      end
      if recorded_rank < sizing.rank("verify", computed.size)
        return [computed, Check.new(SIZE_CHECK, :fail, "recorded size #{recorded} is smaller than computed size #{computed.size} (#{because}); run the checks for #{computed.size} and record it")]
      end
      [computed, Check.new(SIZE_CHECK, :pass, "recorded #{recorded}, computed #{computed.size}, scope #{computed.applied}")]
    rescue TargetError, GitError => e
      [nil, Check.new(SIZE_CHECK, :fail, "cannot compute the size: #{e.message}")]
    end

    def full_suite_check(handoff, block, computed, scoped)
      required = scoped && (computed.nil? || computed.size == Sizing.policy_sizes(@plane).fetch("verify").last)
      owed = scoped ? "none recorded; the full run is still owed before merge (record it in tests.yml, or cite another record's run)" : "none recorded; no scope is declared, so nothing is asked of this record"
      result = FullSuite.new(@record, git: @git).evaluate(block, evidence_sha: handoff["commit_sha"].to_s, required: required, owed_note: owed)
      Check.new(FULL_SUITE_CHECK, result.outcome, result.detail)
    end
  end
end
