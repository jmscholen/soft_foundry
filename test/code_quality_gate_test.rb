# frozen_string_literal: true

require_relative "lifecycle_fixture"

# changes/code-quality-gate: the quality phase (a staff software engineer's
# review of the change's code), where it is asked for, what may block, and
# the profile setting that turns it on.
class CodeQualityGateTest < Minitest::Test
  include LifecycleFixture

  THROUGH_VERIFY = %w[intake discover specify threat_model plan implement verify].freeze
  CLASSED = "quality findings classed"

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)

  def gate(dir, record, phase_id)
    SoftFoundry::Gate.new(record, git: git(dir)).evaluate(plane(dir).phase(phase_id))
  end

  def check(result, name) = result.checks.find { |c| c.name == name }

  # Sets quality_gate.enabled in the fixture repository's profile; nil
  # removes the key.
  def quality_gate!(dir, enabled)
    path = File.join(dir, ".ai", "repository.yml")
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
    enabled.nil? ? data.delete("quality_gate") : data["quality_gate"] = { "enabled" => enabled, "set_by" => "test" }
    File.write(path, YAML.dump(data))
  end

  # A record made by `change new` on `track` at `risk`, in a repository
  # whose profile has the quality gate `gate` (true, false or nil for
  # absent), with `complete` phases planted and committed. `rules` rewrites
  # the record's rules number (:none removes it) and removes the quality
  # directory, as a record made before the phase existed would be.
  def with_quality_record(gate: true, track: "gated", risk: "medium", complete: THROUGH_VERIFY, rules: nil)
    with_fixture_repo do |dir|
      quality_gate!(dir, gate)
      commit_all(dir, "profile")
      sh(dir, "git", "checkout", "-qb", "change/c1")
      code, out = cli(dir, "change", "new", "c1", "--track", track)
      assert_equal 0, code, out
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane(dir))
      set_metadata!(record, status: "in_progress", current_phase: "verify")
      record.update_metadata { |m| m["risk"] = risk }
      if rules
        meta = File.join(record.dir, "metadata.yml")
        text = File.read(meta)
        File.write(meta, rules == :none ? text.sub(/^rules:.*\n/, "") : text.sub(/^rules:.*$/, "rules: #{rules}"))
        FileUtils.rm_rf(File.join(record.dir, "06a-code-quality"))
        record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane(dir))
      end
      commit_all(dir, "record")
      complete.each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases complete") unless complete.empty?
      yield dir, record
    end
  end

  def quality_handoff!(record, status:, findings:, blocking: [])
    phase = record.control_plane.phase("quality")
    record.update_handoff(phase) do |h|
      h["status"] = status
      h["findings"] = findings
      h["blocking"] = blocking
    end
  end

  def finding(id, severity, klass: nil, failure: nil)
    { "id" => id, "severity" => severity, "summary" => "summary of #{id}" }.tap do |f|
      f["class"] = klass if klass
      f["failure"] = failure if failure
    end
  end

  COST = "Two callers compute the total; one rounds before tax and one after, so an order of 3 items is charged 0.01 more by the second."

  # --- REQ-001 (AC-001) -------------------------------------------------------

  def test_the_lifecycle_places_quality_between_verify_and_evaluate
    with_fixture_repo do |dir|
      p = plane(dir)
      quality = p.phase("quality")
      refute_nil quality, "quality phase is defined"
      assert_equal "code-quality", quality.skill
      assert_equal "06a-code-quality", quality.output
      ids = p.phases.map(&:id)
      assert_equal ids.index("verify") + 1, ids.index("quality")
      assert_equal ids.index("evaluate") - 1, ids.index("quality")
      assert p.skill("code-quality").commit_bound?
    end
  end

  def test_change_new_scaffolds_the_quality_directory_and_the_new_rules_number
    with_quality_record(complete: []) do |_dir, record|
      target = File.join(record.dir, "06a-code-quality")
      assert File.file?(File.join(target, "handoff.yml"))
      record.control_plane.skill("code-quality").required_files.each { |f| assert File.file?(File.join(target, f)), f }
      assert_operator record.metadata["rules"], :>, 2
    end
  end

  def test_evaluation_waits_for_quality_where_the_gate_is_on
    with_quality_record(complete: THROUGH_VERIFY + %w[evaluate]) do |dir, record|
      c = check(gate(dir, record, "evaluate"), "predecessor complete")
      assert_equal :fail, c.outcome, c.detail
      assert_includes c.detail, "06a-code-quality"
      refute record.skippable?(plane(dir).phase("quality"))
      complete_phase!(record, "quality", sha: head(dir))
      commit_all(dir, "quality complete")
      c = check(gate(dir, record, "evaluate"), "predecessor complete")
      assert_equal :pass, c.outcome, c.detail
    end
  end

  def test_sealing_verify_makes_quality_the_current_phase
    with_quality_record(complete: THROUGH_VERIFY - %w[verify]) do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      code, out, err = run_cli(dir, "phase", "seal", "verify")
      assert_equal 0, code, out + err
      assert_equal "quality", record.metadata["current_phase"]
    end
  end

  # --- REQ-004 / REQ-012 (AC-002) --------------------------------------------

  def assert_not_asked(reason: nil, **opts)
    with_quality_record(complete: THROUGH_VERIFY + %w[evaluate], **opts) do |dir, record|
      quality = plane(dir).phase("quality")
      assert record.skippable?(quality)
      result = gate(dir, record, "evaluate")
      c = check(result, "predecessor complete")
      assert_equal :pass, c.outcome, c.detail
      assert_empty gate(dir, record, "quality").checks.select { |k| k.outcome == :fail }
      assert_includes record.skip_reason(quality).to_s, reason if reason
      yield dir, record if block_given?
    end
  end

  def test_low_risk_is_not_asked_for_quality
    assert_not_asked(risk: "low", reason: "stepped over by default at low risk")
  end

  def test_the_light_track_is_not_asked_for_quality
    assert_not_asked(track: "light", complete: %w[intake specify implement verify evaluate], reason: "optional on the light track")
  end

  def test_a_record_with_the_earlier_rules_number_is_not_asked_for_quality
    assert_not_asked(rules: 2) do |dir, _record|
      _, out = cli(dir, "change", "status", "c1")
      refute_includes out, "06a-code-quality/handoff.yml is missing"
    end
  end

  def test_a_record_with_no_rules_number_is_not_asked_for_quality
    assert_not_asked(rules: :none)
  end

  def test_a_repository_with_the_gate_off_is_not_asked_for_quality
    assert_not_asked(gate: false, reason: "quality gate is off")
  end

  def test_a_repository_that_does_not_name_the_gate_is_not_asked_for_quality
    assert_not_asked(gate: nil, reason: "quality gate is off")
  end

  def test_change_status_says_why_quality_may_stay_pending
    with_quality_record(gate: false) do |dir, _record|
      _, out = cli(dir, "change", "status", "c1")
      line = out.lines.find { |l| l.include?("06a-code-quality") }
      refute_nil line, out
      assert_includes line, "quality gate is off"
      lines = out.lines.map(&:strip)
      assert_operator lines.index { |l| l.start_with?("06-verification") }, :<, lines.index { |l| l.start_with?("06a-code-quality") }
      assert_operator lines.index { |l| l.start_with?("06a-code-quality") }, :<, lines.index { |l| l.start_with?("07-evaluation") }
    end
  end

  def test_a_change_may_ask_for_quality_where_the_gate_is_off
    with_quality_record(gate: false, complete: THROUGH_VERIFY + %w[evaluate]) do |dir, record|
      record.update_metadata { |m| m["run_phases"] = ["quality"] }
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane(dir))
      refute record.skippable?(plane(dir).phase("quality"))
    end
  end

  # --- REQ-005 / REQ-006 (AC-003) --------------------------------------------

  def test_a_classed_blocking_finding_blocks_the_phase_and_points_to_remediation
    %w[duplication reliability].each do |klass|
      with_quality_record do |dir, record|
        quality_handoff!(record, status: "blocked", blocking: ["QUAL-001"], findings: [finding("QUAL-001", "blocking", klass: klass, failure: COST)])
        result = gate(dir, record, "quality")
        assert_equal "blocked", result.status
        assert_equal :pass, check(result, CLASSED).outcome, check(result, CLASSED).detail
        assert_empty result.checks.select { |c| c.outcome == :fail }
        assert_equal "remediate", plane(dir).transitions.dig("quality", "on_blocking_findings")
      end
    end
  end

  def test_a_blocking_finding_without_a_valid_class_or_cost_fails_the_gate
    cases = {
      "no class" => finding("QUAL-001", "blocking", failure: COST),
      "class style" => finding("QUAL-001", "blocking", klass: "style", failure: COST),
      "no failure" => finding("QUAL-001", "blocking", klass: "performance")
    }
    cases.each do |label, f|
      with_quality_record do |dir, record|
        quality_handoff!(record, status: "blocked", blocking: ["QUAL-001"], findings: [f])
        c = check(gate(dir, record, "quality"), CLASSED)
        assert_equal :fail, c.outcome, label
        assert_includes c.detail, "QUAL-001", label
      end
    end
  end

  def test_a_handoff_with_findings_of_major_or_lower_can_complete
    with_quality_record(complete: THROUGH_VERIFY + %w[quality]) do |dir, record|
      quality_handoff!(record, status: "complete", findings: [finding("QUAL-001", "major", failure: COST), finding("QUAL-002", "minor")])
      commit_all(dir, "quality findings")
      result = gate(dir, record, "quality")
      assert_equal :pass, check(result, CLASSED).outcome
      assert_equal :pass, check(result, "findings explained").outcome
    end
  end

  def test_a_complete_handoff_may_not_carry_a_blocking_finding
    with_quality_record(complete: THROUGH_VERIFY + %w[quality]) do |dir, record|
      quality_handoff!(record, status: "complete", findings: [finding("QUAL-001", "blocking", klass: "duplication", failure: COST)])
      c = check(gate(dir, record, "quality"), CLASSED)
      assert_equal :fail, c.outcome
      assert_includes c.detail, "QUAL-001"
    end
  end

  # --- REQ-003 (AC-004) -------------------------------------------------------

  def test_the_quality_phase_writes_only_its_own_directory
    with_quality_record(complete: THROUGH_VERIFY) do |dir, record|
      set_metadata!(record, current_phase: "quality")
      commit_all(dir, "at quality")
      guard = SoftFoundry::Guard.new(dir)
      assert_equal :allow, guard.decide("Edit", { "file_path" => "changes/c1/06a-code-quality/design.md" }).outcome
      ["lib/app.rb", "test/app_test.rb", "changes/c1/06-verification/tests.yml", "changes/c1/13-review/functional.md", ".ai/rules/ruby.md", "README.md"].each do |path|
        d = guard.decide("Edit", { "file_path" => path })
        assert d.violation?, path
        assert_equal "code-quality", d.skill
      end
      assert_equal :allow, guard.decide("Read", { "file_path" => "lib/app.rb" }).outcome
      assert guard.decide("Read", { "file_path" => ".ai/harness-evals/README.md" }).violation?
    end
  end

  # --- REQ-007 (AC-006) -------------------------------------------------------

  def test_quality_evidence_goes_stale_when_code_changes
    with_quality_record(complete: THROUGH_VERIFY + %w[quality]) do |dir, record|
      assert_equal :pass, check(gate(dir, record, "quality"), "evidence current").outcome
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code change")
      assert_equal :fail, check(gate(dir, record, "quality"), "evidence current").outcome
    end
  end

  def test_reopening_verify_resets_quality
    with_fixture_repo do |dir|
      p = plane(dir)
      assert_includes p.downstream(p.phase("verify")).map(&:id), "quality"
      assert_includes p.downstream(p.phase("remediate")).map(&:id), "quality"
    end
  end

  # --- REQ-008 (AC-007), REQ-006 (AC-008) -------------------------------------

  def test_the_quality_gate_carries_the_checks_review_carries
    with_fixture_repo do |dir|
      p = plane(dir)
      names = SoftFoundry::Gate.checks_for(p, p.phase("quality"))
      review = SoftFoundry::Gate.checks_for(p, p.phase("review"))
      [SoftFoundry::Gate::FRESH_CHECK, SoftFoundry::Gate::CAP_CHECK, SoftFoundry::Gate::OUTSIDE_CHECK, "findings explained", "evidence current"].each do |name|
        assert_includes review, name
        assert_includes names, name
      end
      assert_includes names, CLASSED
      assert_equal %w[implement remediate], p.skill("code-quality").definition["prefer_different_provider_from"]
    end
  end

  def test_quality_without_a_fresh_session_fails_in_block_mode
    with_quality_record(complete: THROUGH_VERIFY) do |dir, record|
      complete_phase!(record, "quality", sha: head(dir), runner: false)
      commit_all(dir, "quality by the open session")
      policy = File.join(dir, ".ai", "policies", "enforcement.yml")
      File.write(policy, File.read(policy).sub(/^(\s*mode:\s*).*$/, '\1block'))
      c = check(gate(dir, record, "quality"), SoftFoundry::Gate::FRESH_CHECK)
      assert_equal :fail, c.outcome, c.detail
    end
  end

  # --- REQ-004 (AC-012) -------------------------------------------------------

  def scanned_gate(dir)
    SoftFoundry::MaturityScan.new(dir, control_plane: plane(dir)).run!
    plane(dir).repository_profile["quality_gate"]
  end

  def test_onboarding_turns_the_gate_on_for_a_scripting_language
    with_fixture_repo do |dir|
      quality_gate!(dir, nil)
      File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'\n")
      setting = scanned_gate(dir)
      assert_equal true, setting["enabled"]
      assert_includes setting["set_by"], "ruby"
    end
  end

  def test_onboarding_leaves_the_gate_off_for_other_languages
    with_fixture_repo do |dir|
      quality_gate!(dir, nil)
      File.write(File.join(dir, "go.mod"), "module example\n")
      assert_equal false, scanned_gate(dir)["enabled"]
    end
  end

  def test_onboarding_keeps_a_setting_a_person_made
    with_fixture_repo do |dir|
      quality_gate!(dir, false)
      File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'\n")
      setting = scanned_gate(dir)
      assert_equal false, setting["enabled"]
      assert_equal "test", setting["set_by"]
    end
  end

  # --- REQ-002, REQ-009, REQ-010, REQ-013, REQ-014 (AC-005, AC-009, AC-011) ---

  def skill_text(name) = File.read(File.join(FoundryFixture::REPO_ROOT, ".ai", "skills", name, "SKILL.md"))

  def test_the_skill_states_the_questions_the_classes_and_its_limits
    text = skill_text("code-quality")
    %w[duplication performance simpler_design unmet_need reliability].each { |klass| assert_includes text, klass }
    assert_includes text, "staff software engineer"
    assert_includes text, "does not repair"
    refute_match(/rails/i, text)
    templates = Dir.children(File.join(FoundryFixture::REPO_ROOT, ".ai", "skills", "code-quality", "template"))
    %w[fit.md design.md duplication.md performance.md reliability.md clarity.md consolidated.md].each { |f| assert_includes templates, f }
  end

  def test_review_judgment_remediation_and_the_rails_rules_name_the_phase
    assert_includes skill_text("review"), "06a-code-quality"
    assert_includes skill_text("final-judgment"), "06a-code-quality"
    remediation = skill_text("remediation")
    assert_includes remediation, "observable contract"
    assert_includes remediation, "smallest coherent edit"
    rails = File.read(File.join(FoundryFixture::REPO_ROOT, ".ai", "rules", "rails.md"))
    ["Associations and data modeling", "Object design", "Performance", "Reliability"].each { |heading| assert_includes rails, heading }
  end

  def test_help_and_documentation_describe_the_phase
    _, out = cli(FoundryFixture::REPO_ROOT, "help")
    assert_includes out, "quality"
    %w[README.md AGENTS.md .ai/README.md docs/user/code-quality-review.md].each do |path|
      assert_includes File.read(File.join(FoundryFixture::REPO_ROOT, path)), "quality_gate", path
    end
  end
end
