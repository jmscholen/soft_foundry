# frozen_string_literal: true

require_relative "lifecycle_fixture"

# changes/process-speed: the remediation cap, criterion tiers and the
# must-list approval, person checks, the blocked basis, outside-change
# findings, default low-risk waivers, documentation-only sizing and the
# documentation-only reopen.
class ProcessSpeedTest < Minitest::Test
  include LifecycleFixture

  MUSTS = %w[AC-001 AC-002].freeze

  # --- fixture helpers ----------------------------------------------------

  def new_rules!(record, risk: nil)
    record.update_metadata do |m|
      m["rules"] = 2
      m["risk"] = risk if risk
    end
  end

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)

  def reopen(dir, record, phase_id, reason: "findings to fix", source: "manual", env: {}, docs_only: false)
    p = plane(dir)
    SoftFoundry::PhaseReopen.new(dir, plane: p, git: git(dir), record: record)
                            .call(p.phase(phase_id), reason: reason, source: source, env: env, docs_only: docs_only)
  end

  def seal(dir, record, phase_id, env: {})
    p = plane(dir)
    SoftFoundry::PhaseSeal.new(dir, plane: p, git: git(dir), record: record, env: env).call(p.phase(phase_id))
  end

  def gate(dir, record, phase_id)
    SoftFoundry::Gate.new(record, git: git(dir)).evaluate(plane(dir).phase(phase_id))
  end

  def check(result, name) = result.checks.find { |c| c.name == name }

  # Commits whose subject is the remediate seal, as `rounds` sealed rounds.
  def sealed_rounds!(dir, record, rounds)
    rounds.times do |i|
      File.write(File.join(record.dir, "09-remediation", "round-#{i}.md"), "round #{i}\n")
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "Record #{record.slug} remediate")
    end
  end

  def criteria!(record, entries, person_checks: nil)
    path = File.join(record.dir, "02-specification", "acceptance-criteria.yml")
    data = { "criteria" => entries.map { |id, tier| { "id" => id, "tier" => tier, "requirements" => ["REQ-001"], "given" => "g", "when" => "w", "then" => "t", "verified_by" => [] }.compact } }
    data["person_checks"] = person_checks if person_checks
    File.write(path, YAML.dump(data))
  end

  def decide!(record, entry)
    record.update_metadata { |m| m["human_decisions"] = Array(m["human_decisions"]) + [entry] }
  end

  def approve!(record, ids)
    decide!(record, { "boundary" => "must criteria approval", "criteria" => ids, "decided_by" => "maintainer", "decided_at" => "2026-11-13", "decision" => "approved" })
  end

  # --- REQ-001 rules version ----------------------------------------------

  def test_change_new_declares_the_rules_version
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c9")
      cli(dir, "change", "new", "c9")
      meta = YAML.safe_load_file(File.join(dir, "changes", "c9", "metadata.yml"), permitted_classes: [Time, Date])
      assert_equal 2, meta["rules"]
    end
  end

  def test_new_checks_skip_on_a_legacy_record
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      record.update_metadata { |m| m.delete("rules") }
      commit_all(dir, "legacy")
      %w[specify review judge].each do |id|
        gate(dir, record, id).checks.select { |c| SoftFoundry::Gate::PROCESS_CHECKS.include?(c.name) }.each do |c|
          assert_equal :skip, c.outcome, "#{id} #{c.name}"
          assert_includes c.detail, "legacy record"
        end
      end
    end
  end

  def test_rules_version_removed_after_intake_fails_the_first_phase
    with_lifecycle_record(complete: []) do |dir, record|
      new_rules!(record)
      complete_phase!(record, "intake", sha: head(dir))
      commit_all(dir, "Record c1 intake")
      record.update_metadata { |m| m.delete("rules") }
      result = check(gate(dir, record, "intake"), "rules kept")
      assert_equal :fail, result.outcome
      assert_includes result.detail, "rules"
    end
  end

  # --- REQ-002 / REQ-003 remediation cap -----------------------------------

  def test_round_count_takes_the_larger_of_commits_and_reopenings
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      rules = SoftFoundry::ProcessRules.new(record, git: git(dir))
      assert_equal 2, rules.remediation_rounds
      record.update_metadata do |m|
        m["phase_reopenings"] = Array.new(3) { { "phase" => "remediate", "reset" => %w[verify remediate], "previous" => { "remediate" => { "status" => "complete" } } } }
      end
      assert_equal 3, SoftFoundry::ProcessRules.new(record, git: git(dir)).remediation_rounds
    end
  end

  def test_reopen_at_the_cap_is_refused_and_parks_the_change
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      before = tree_bytes(dir, "changes/c1").reject { |k, _| k.end_with?("metadata.yml") }
      error = assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "remediate") }
      %w[accept_residual narrow reject remediation\ cap awaiting_human].each { |w| assert_includes error.message, w }
      assert_equal "awaiting_human", record.metadata["status"]
      assert_equal before, tree_bytes(dir, "changes/c1").reject { |k, _| k.end_with?("metadata.yml") }
      assert_empty Array(record.metadata["phase_reopenings"])
    end
  end

  def test_reopen_below_the_cap_is_permitted
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 1)
      result = reopen(dir, record, "remediate")
      assert_includes result.reset.map(&:id), "remediate"
    end
  end

  def test_a_cap_decision_lets_one_more_round_through
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      decide!(record, { "boundary" => "remediation cap", "rounds" => 2, "decision" => "narrow", "decided_by" => "maintainer", "decided_at" => "2026-11-13" })
      assert_includes reopen(dir, record, "remediate").reset.map(&:id), "remediate"
    end
  end

  def test_a_reject_decision_never_lets_a_round_through
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      decide!(record, { "boundary" => "remediation cap", "rounds" => 2, "decision" => "reject", "decided_by" => "maintainer", "decided_at" => "2026-11-13" })
      error = assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "remediate") }
      assert_includes error.message, "REJECTED"
    end
  end

  def test_the_cap_does_not_apply_to_a_legacy_record
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      sealed_rounds!(dir, record, 3)
      assert_includes reopen(dir, record, "remediate").reset.map(&:id), "remediate"
    end
  end

  def test_sealing_a_third_round_without_a_reopen_is_refused
    with_lifecycle_record(complete: LIFECYCLE - %w[review judge], current_phase: "remediate") do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      commit_all(dir, "rules")
      complete_phase!(record, "remediate", sha: head(dir))
      result = seal(dir, record, "remediate")
      assert_equal :refused, result.outcome
      assert_includes result.lines.join, "remediation cap"
      assert_equal "awaiting_human", record.metadata["status"]
    end
  end

  def test_review_and_judge_gates_fail_above_the_cap_without_a_decision
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 3)
      %w[review judge].each do |id|
        c = check(gate(dir, record, id), "remediation within cap")
        assert_equal :fail, c.outcome, id
        assert_includes c.detail, "remediation cap"
      end
      decide!(record, { "boundary" => "remediation cap", "rounds" => 2, "decision" => "accept_residual", "decided_by" => "maintainer", "decided_at" => "2026-11-13" })
      %w[review judge].each { |id| assert_equal :pass, check(gate(dir, record, id), "remediation within cap").outcome, id }
    end
  end

  # --- REQ-004 / REQ-005 tiers, cap, approval -------------------------------

  def test_missing_or_unknown_tier_fails_the_specify_gate
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", nil], ["AC-002", "maybe"]])
      approve!(record, [])
      c = check(gate(dir, record, "specify"), "criteria tiered")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "AC-001"
      assert_includes c.detail, "AC-002"
      assert_includes c.detail, "must"
    end
  end

  def test_must_count_over_the_risk_cap_fails
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record, risk: "low")
      criteria!(record, (1..4).map { |i| ["AC-00#{i}", "must"] })
      c = check(gate(dir, record, "specify"), "criteria tiered")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "4"
      assert_includes c.detail, "3"
      assert_includes c.detail, "must_criteria_cap"
      criteria!(record, (1..3).map { |i| ["AC-00#{i}", "must"] } + [["AC-004", "should"]])
      assert_equal :pass, check(gate(dir, record, "specify"), "criteria tiered").outcome
    end
  end

  def test_specify_needs_an_approval_matching_the_must_set
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"], ["AC-002", "must"], ["AC-003", "should"]])
      c = check(gate(dir, record, "specify"), "must criteria approved")
      assert_equal :fail, c.outcome
      approve!(record, %w[AC-001])
      c = check(gate(dir, record, "specify"), "must criteria approved")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "AC-002"
      record.update_metadata { |m| m["human_decisions"] = [] }
      approve!(record, MUSTS)
      assert_equal :pass, check(gate(dir, record, "specify"), "must criteria approved").outcome
    end
  end

  # --- REQ-006 coverage by tier ---------------------------------------------

  def test_uncovered_should_warns_and_uncovered_must_fails_at_judgment
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"], ["AC-009", "should"]])
      c = check(gate(dir, record, "judge"), "criteria covered")
      assert_equal :warn, c.outcome
      assert_includes c.detail, "AC-009"
      criteria!(record, [["AC-001", "must"], ["AC-008", "must"]])
      c = check(gate(dir, record, "judge"), "criteria covered")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "AC-008"
    end
  end

  # --- REQ-007 person checks ------------------------------------------------

  def test_person_checks_are_not_criteria_and_become_release_items
    with_finished_record do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"]], person_checks: [{ "id" => "PC-001", "description" => "open the page" }, { "id" => "PC-002", "description" => "look at the render" }])
      approve!(record, %w[AC-001])
      commit_all(dir, "person checks")
      c = check(gate(dir, record, "judge"), "criteria covered")
      refute_includes c.detail.to_s, "PC-00"
      code, _out, err = run_cli(dir, "change", "release", "--item", "GOLIVE-1=flip the flag")
      assert_equal 0, code, err
      ids = record.metadata.dig("release", "items").map { |i| i["id"] }
      assert_includes ids, "PC-001"
      assert_includes ids, "PC-002"
    end
  end

  # --- REQ-008 / REQ-009 blocked basis, outside-change findings --------------

  def blocked!(record, blocked_by)
    final = File.join(record.phase_dir(record.control_plane.phase("judge")), "final.md")
    File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nBLOCKED"))
    data = record.judgment_evidence
    data["blocked_by"] = blocked_by
    File.write(record.judgment_evidence_path, YAML.dump(data))
  end

  def review_findings!(record, findings)
    record.update_handoff(record.control_plane.phase("review")) { |h| h["findings"] = findings }
  end

  def test_blocked_judgment_must_name_a_must_criterion_or_a_blocking_finding
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"], ["AC-002", "should"]])
      review_findings!(record, [
        { "id" => "REV-001", "severity" => "blocking", "summary" => "s", "failure" => "f" },
        { "id" => "REV-002", "severity" => "blocking", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "guard change", "paths" => ["lib/guard.rb"] }
      ])
      { [] => "names nothing", ["AC-002"] => "should", ["REV-002"] => "outside" }.each do |names, word|
        blocked!(record, names)
        c = check(gate(dir, record, "judge"), "blocked basis")
        assert_equal :fail, c.outcome, names.inspect
        assert_includes c.detail, word
      end
      blocked!(record, ["AC-001"])
      assert_equal :pass, check(gate(dir, record, "judge"), "blocked basis").outcome
      blocked!(record, ["REV-001"])
      assert_equal :pass, check(gate(dir, record, "judge"), "blocked basis").outcome
    end
  end

  def test_outside_change_finding_needs_a_follow_up_and_paths_outside_the_diff
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record)
      review_findings!(record, [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true }])
      c = check(gate(dir, record, "review"), "outside-change findings")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "REV-001"
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "change app")
      review_findings!(record, [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "x", "paths" => ["lib/app.rb"] }])
      c = check(gate(dir, record, "review"), "outside-change findings")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "lib/app.rb"
      review_findings!(record, [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "guard follow-up", "paths" => ["lib/other.rb"] }])
      assert_equal :pass, check(gate(dir, record, "review"), "outside-change findings").outcome
    end
  end

  # --- REQ-010 default waivers ------------------------------------------------

  def test_low_risk_steps_over_waivable_phases_unless_run_phases_asks
    with_lifecycle_record(complete: []) do |dir, record|
      new_rules!(record, risk: "low")
      record.update_metadata { |m| m["run_phases"] = ["attack"] }
      p = plane(dir)
      assert record.skippable?(p.phase("threat_model"))
      refute record.skippable?(p.phase("attack"))
      refute record.skippable?(p.phase("review"))
      complete_phase!(record, "intake", sha: head(dir))
      c = check(gate(dir, record, "intake"), "waivers permitted")
      assert_equal :pass, c.outcome
      assert_includes c.detail, "default"
      assert_includes c.detail, "threat_model"
      record.update_metadata { |m| m.delete("rules") }
      refute record.skippable?(p.phase("threat_model"))
    end
  end

  # --- REQ-011 documentation-only sizing ---------------------------------------

  def test_documentation_paths
    with_fixture_repo do |dir|
      p = plane(dir)
      %w[README.md docs/user/x.md changes/c1/notes.md].each { |path| assert SoftFoundry::ProcessRules.documentation_path?(p, path, "c1"), path }
      %w[lib/x.rb .ai/workflow.yml test/x_test.rb changes/other/x.md lib/notes.md].each { |path| refute SoftFoundry::ProcessRules.documentation_path?(p, path, "c1"), path }
    end
  end

  def test_documentation_only_diff_gets_the_smaller_size
    with_lifecycle_record(complete: LIFECYCLE - %w[verify evaluate attack review judge]) do |dir, record|
      new_rules!(record)
      commit_all(dir, "Record c1 plan")
      File.write(File.join(dir, "README.md"), "# readme\n")
      FileUtils.mkdir_p(File.join(dir, "docs"))
      File.write(File.join(dir, "docs", "guide.md"), "guide\n")
      commit_all(dir, "docs")
      sizing = SoftFoundry::Sizing.new(record, git: git(dir))
      %w[verify attack].each do |phase|
        result = sizing.compute(phase, since: sh(dir, "git", "rev-parse", "HEAD~1").strip)
        assert_equal sizing.sizes(phase).first, result.size, phase
        assert_includes result.reasons.join, "documentation-only"
      end
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      commit_all(dir, "code")
      assert_equal sizing.sizes("verify").last, sizing.compute("verify", since: sh(dir, "git", "rev-parse", "HEAD~2").strip).size
    end
  end

  # --- REQ-012 documentation-only reopen -----------------------------------------

  def test_docs_only_reopen_keeps_verify_evaluate_and_attack
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 1)
      result = reopen(dir, record, "remediate", docs_only: true)
      assert_equal %w[remediate review judge], result.reset.map(&:id)
      s = statuses(record)
      %w[verify evaluate attack].each { |id| assert_equal "complete", s[id], id }
      assert_equal true, record.metadata["phase_reopenings"].last["docs_only"]
    end
  end

  def test_docs_only_remediation_seal_refuses_a_code_change
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 1)
      commit_all(dir, "rules")
      reopen(dir, record, "remediate", docs_only: true)
      commit_all(dir, "reopened")
      File.write(File.join(dir, "lib", "app.rb"), "puts 4\n")
      commit_all(dir, "code under docs-only")
      complete_phase!(record, "remediate", sha: head(dir))
      result = seal(dir, record, "remediate")
      assert_equal :refused, result.outcome
      assert_includes result.lines.join, "lib/app.rb"
      assert_includes result.lines.join, "--docs-only"
    end
  end

  def test_docs_only_remediation_seal_allows_documentation
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 1)
      commit_all(dir, "rules")
      reopen(dir, record, "remediate", docs_only: true)
      commit_all(dir, "reopened")
      File.write(File.join(dir, "README.md"), "# fixed wording\n")
      commit_all(dir, "wording")
      complete_phase!(record, "remediate", sha: head(dir))
      refute_equal :refused, seal(dir, record, "remediate").outcome
    end
  end

  # --- REQ-016 output survives stripping -----------------------------------------

  def test_cap_refusal_reads_without_color_or_non_ascii
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      text = SoftFoundry::ProcessRules.new(record, git: git(dir)).cap_refusal
      stripped = text.gsub(/\e\[[0-9;]*m/, "").encode("ASCII", invalid: :replace, undef: :replace, replace: "")
      %w[awaiting_human remediation\ cap accept_residual narrow reject in_progress].each { |w| assert_includes stripped, w }
    end
  end
end
