# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Remediation of the adversarial-testing findings on changes/gate-hardening
# (08-attack/handoff.yml ATK-001, ATK-002, ATK-004, ATK-005, ATK-008, ATK-009).
class RemediationGateHardeningTest < Minitest::Test
  include LifecycleFixture

  THROUGH_VERIFY = LIFECYCLE.take(7)

  def check(dir, record, phase, name)
    result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate(phase)
    result.checks.find { |c| c.name == name } || flunk("no check #{name.inspect}: #{result.checks.map(&:name)}")
  end

  def phase_file(record, id, rel) = File.join(record.phase_dir(record.control_plane.phase(id)), rel)

  def edit_yaml(record, id, rel)
    path = phase_file(record, id, rel)
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
    yield data
    File.write(path, YAML.dump(data))
  end

  # ATK-001: a recorded phase's commit_sha may not be moved forward without a reopening.
  def test_rewriting_a_recorded_commit_sha_forward_is_refused_until_the_phase_is_reopened
    with_lifecycle_record(complete: THROUGH_VERIFY, current_phase: "evaluate") do |dir, record|
      recorded = head(dir)
      verify = record.control_plane.phase("verify")
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed after verification")
      record.update_handoff(verify) { |h| h["commit_sha"] = head(dir) }
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, recorded[0, 12]
      assert_includes lineage.detail, head(dir)[0, 12]
      assert_includes lineage.detail, "phase reopen"
      code, out, err = run_cli(dir, "phase", "seal", "verify")
      assert_equal 2, code, out + err
      assert_equal "code changed after verification", sh(dir, "git", "log", "--format=%s", "-n", "1").strip

      code, _out, err = run_cli(dir, "phase", "reopen", "verify", "--reason", "code changed")
      assert_equal 0, code, err
      complete_phase!(record, "verify", sha: head(dir))
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :pass, lineage.outcome, lineage.detail
    end
  end

  # ATK-004: an acknowledgement names the whole check id.
  def test_fail_acknowledgement_matches_whole_ids
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "tests.yml") do |t|
        t["checks"] = [
          { "id" => "CHECK-1", "kind" => "tests", "command" => "x", "result" => "fail", "evidence" => "evidence/recorded.txt", "criteria" => [] },
          { "id" => "CHECK-10", "kind" => "tests", "command" => "y", "result" => "pass", "evidence" => "evidence/recorded.txt", "criteria" => ["AC-001"] }
        ]
      end
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "minor", "summary" => "CHECK-10 took a while" }] }
      results = check(dir, record, "verify", "test results recorded")
      assert_equal :fail, results.outcome, results.detail
      assert_includes results.detail, "CHECK-1 (fail)"
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "minor", "summary" => "CHECK-1 fails on the inherited variable" }] }
      assert_equal :pass, check(dir, record, "verify", "test results recorded").outcome
    end
  end

  # ATK-005: a reason is at least two words, and only real criteria can be set aside.
  def test_hollow_reasons_and_unknown_criteria_are_refused
    with_lifecycle_record(complete: LIFECYCLE, current_phase: "learn") do |dir, record|
      edit_yaml(record, "specify", "acceptance-criteria.yml") do |a|
        a["criteria"] << { "id" => "AC-002", "requirements" => ["REQ-001"], "given" => "g", "when" => "w", "then" => "t", "verified_by" => [] }
      end
      ["-", "n/a", ".", "carried"].each do |hollow|
        edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-002", "reason" => hollow }] }
        covered = check(dir, record, "judge", "criteria covered")
        assert_equal :fail, covered.outcome, "reason #{hollow.inspect}: #{covered.detail}"
      end
      edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-002", "reason" => "needs a production observation" }, { "id" => "AC-999", "reason" => "not a criterion at all" }] }
      covered = check(dir, record, "judge", "criteria covered")
      assert_equal :fail, covered.outcome, covered.detail
      assert_includes covered.detail, "AC-999"
      edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-002", "reason" => "needs a production observation" }] }
      assert_equal :pass, check(dir, record, "judge", "criteria covered").outcome
    end
  end

  # ATK-008: a manifest that vouches for nothing is refused where evidence is the point.
  def test_empty_artifacts_list_fails
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "evidence/manifest.yml") { |m| m["artifacts"] = [] }
      manifest = check(dir, record, "verify", "evidence manifest verified")
      assert_equal :fail, manifest.outcome, manifest.detail
      assert_includes manifest.detail, "lists no artifact"
    end
  end

  # ATK-002: a seal onto the checked-out branch because the record's does not exist says so.
  def test_seal_names_a_missing_record_branch
    with_lifecycle_record(complete: [], current_phase: "intake", status: "intake") do |dir, record|
      record.update_metadata { |m| m["git"]["branch"] = "change/never-created" }
      commit_all(dir, "point at a branch that does not exist")
      complete_phase!(record, "intake", sha: head(dir))
      code, out, err = run_cli(dir, "phase", "seal", "intake")
      assert_equal 0, code, out + err
      note = out.lines.find { |l| l.start_with?("note:") && l.include?("change/never-created") }
      assert note, out
      assert_includes note, "change/c1"
    end
  end

  # ATK-009: the runner stamp is one of the runner's own names, not any prefix.
  def test_fresh_session_stamp_must_be_a_real_runner
    with_lifecycle_record(complete: LIFECYCLE.take(9), current_phase: "review") do |dir, record|
      path = File.join(dir, ".ai", "policies", "enforcement.yml")
      File.write(path, File.read(path).sub(/^  mode: \w+/, "  mode: block"))
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "--allow-empty", "-m", "block")
      complete_phase!(record, "review", sha: head(dir), runner: false)
      record.update_handoff(record.control_plane.phase("review")) { |h| h["executed_by"] = { "runner" => "soft-foundry phase run --fake", "fresh_context" => true } }
      assert_equal :fail, check(dir, record, "review", "fresh session recorded").outcome
      record.update_handoff(record.control_plane.phase("review")) { |h| h["executed_by"] = { "runner" => "soft-foundry phase run --panel", "fresh_context" => true } }
      assert_equal :pass, check(dir, record, "review", "fresh session recorded").outcome
    end
  end
end
