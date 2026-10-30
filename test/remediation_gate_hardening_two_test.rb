# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Second remediation of the adversarial-testing findings on
# changes/gate-hardening (08-attack/handoff.yml ATK-010 through ATK-013,
# and the carried ATK-006 and ATK-007).
class RemediationGateHardeningTwoTest < Minitest::Test
  include LifecycleFixture

  def check(dir, record, phase, name)
    result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate(phase)
    result.checks.find { |c| c.name == name } || flunk("no check #{name.inspect}: #{result.checks.map(&:name)}")
  end

  def edit_yaml(record, id, rel)
    path = File.join(record.phase_dir(record.control_plane.phase(id)), rel)
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
    yield data
    File.write(path, YAML.dump(data))
  end

  # A verify phase sealed the way the tool seals it: the commit subject is
  # `Record <slug> <phase>`, so the test can tell it from a hand commit.
  def with_sealed_verify
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      commit_all(dir, "Record c1 verify")
      yield dir, record, head(dir)
    end
  end

  def change_code_and_rewrite_commit_sha(dir, record)
    File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
    commit_all(dir, "code changed after verification")
    record.update_handoff(record.control_plane.phase("verify")) { |h| h["commit_sha"] = head(dir) }
  end

  # ATK-010: a hand commit of the rewritten handoff does not become the record.
  def test_a_hand_committed_commit_sha_rewrite_is_refused
    with_sealed_verify do |dir, record, recorded|
      change_code_and_rewrite_commit_sha(dir, record)
      commit_all(dir, "tidy the handoff")
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, recorded[0, 12]
      assert_includes lineage.detail, "phase reopen"
    end
  end

  # ATK-011: a reopening that reran nothing does not license the rewrite.
  def test_a_reopening_without_changed_evidence_does_not_license_the_rewrite
    with_sealed_verify do |dir, record, recorded|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed after verification")
      code, _out, err = run_cli(dir, "phase", "reopen", "verify", "--reason", "code changed")
      assert_equal 0, code, err
      complete_phase!(record, "verify", sha: head(dir))
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, "evidence"
      results = File.join(record.phase_dir(record.control_plane.phase("verify")), "results.md")
      File.write(results, "#{File.read(results)}\nRerun at #{head(dir)[0, 12]}\n")
      assert_equal :pass, check(dir, record, "verify", "commit lineage").outcome
      refute_equal recorded, head(dir)
    end
  end

  # ATK-012: the recorded commit written in another form is the same commit.
  def test_an_abbreviated_recorded_commit_sha_is_accepted
    with_sealed_verify do |dir, record, _recorded|
      sha = record.handoff(record.control_plane.phase("verify"))["commit_sha"]
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["commit_sha"] = sha[0, 12] }
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :pass, lineage.outcome, lineage.detail
    end
  end

  # ATK-013: a reason says something, and an id is delimited.
  def test_repeated_or_non_string_reasons_are_refused
    with_lifecycle_record(complete: LIFECYCLE, current_phase: "learn") do |dir, record|
      edit_yaml(record, "specify", "acceptance-criteria.yml") do |a|
        a["criteria"] << { "id" => "AC-002", "requirements" => ["REQ-001"], "given" => "g", "when" => "w", "then" => "t", "verified_by" => [] }
      end
      ["no no", "no no no", %w[needs production], { "needs" => "production" }].each do |reason|
        edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-002", "reason" => reason }] }
        covered = check(dir, record, "judge", "criteria covered")
        assert_equal :fail, covered.outcome, "reason #{reason.inspect}: #{covered.detail}"
      end
    end
  end

  def test_an_id_followed_by_a_dot_digit_or_slash_does_not_acknowledge_it
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "tests.yml") do |t|
        t["checks"] = [{ "id" => "CHECK-1", "kind" => "tests", "command" => "x", "result" => "fail", "evidence" => "evidence/recorded.txt", "criteria" => [] }]
      end
      ["CHECK-1.5 is slow", "CHECK-1/2 is slow"].each do |summary|
        record.update_handoff(record.control_plane.phase("verify")) { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "minor", "summary" => summary }] }
        assert_equal :fail, check(dir, record, "verify", "test results recorded").outcome, summary
      end
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "minor", "summary" => "CHECK-1. It fails." }] }
      assert_equal :pass, check(dir, record, "verify", "test results recorded").outcome
    end
  end

  def test_a_manifest_of_only_empty_files_fails
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      verify = record.control_plane.phase("verify")
      empty = File.join(record.phase_dir(verify), "evidence", "empty.txt")
      File.write(empty, "")
      edit_yaml(record, "verify", "evidence/manifest.yml") do |m|
        m["artifacts"] = [{ "path" => "evidence/empty.txt", "produced_by" => "x", "sha256" => Digest::SHA256.file(empty).hexdigest }]
      end
      manifest = check(dir, record, "verify", "evidence manifest verified")
      assert_equal :fail, manifest.outcome, manifest.detail
      assert_includes manifest.detail, "empty"
    end
  end

  # ATK-006: a repository without an enforcement policy is told what that costs.
  def test_check_warns_when_the_enforcement_policy_is_missing
    with_fixture_repo do |dir|
      FileUtils.rm(File.join(dir, ".ai", "policies", "enforcement.yml"))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      finding = findings.find { |f| f.message.include?("enforcement.yml") }
      assert finding, findings.map(&:message).inspect
      assert_equal :warning, finding.level
      assert_includes finding.message, "fresh session"
    end
  end

  # ATK-007: a seal says which other metadata keys a person edited by hand.
  def test_seal_names_hand_edited_metadata_keys
    with_lifecycle_record(complete: [], current_phase: "intake", status: "intake") do |dir, record|
      complete_phase!(record, "intake", sha: head(dir))
      record.update_metadata { |m| m["risk"] = "low" }
      code, out, err = run_cli(dir, "phase", "seal", "intake")
      assert_equal 0, code, out + err
      note = out.lines.find { |l| l.start_with?("note:") && l.include?("metadata.yml") && l.include?("risk") }
      assert note, out
    end
  end
end
