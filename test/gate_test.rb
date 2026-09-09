# frozen_string_literal: true

require_relative "test_helper"

class GateTest < Minitest::Test
  include FoundryFixture

  def with_record
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      yield dir, plane, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def test_pending_phases_are_skipped_and_do_not_fail
    with_record do |_dir, _plane, _record, gate|
      results = gate.evaluate_all
      assert results.all?(&:skipped?)
      refute results.any?(&:failed?)
    end
  end

  def test_complete_phase_with_placeholders_fails
    with_record do |dir, _plane, record, gate|
      complete_phase!(record, "intake", sha: head(dir), fill: false)
      result = gate.evaluate("intake")
      assert result.failed?
      assert_includes result.checks.map(&:name), "no placeholders"
      assert_equal :fail, result.checks.find { |c| c.name == "no placeholders" }.outcome
    end
  end

  def test_complete_phase_passes_when_filled_and_bound_to_head
    with_record do |dir, _plane, record, gate|
      complete_phase!(record, "intake", sha: head(dir))
      result = gate.evaluate("intake")
      refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
    end
  end

  def test_predecessor_must_be_complete
    with_record do |dir, _plane, record, gate|
      complete_phase!(record, "discover", sha: head(dir))
      result = gate.evaluate("discover")
      assert result.failed?
      assert_equal :fail, result.checks.find { |c| c.name == "predecessor complete" }.outcome
    end
  end

  def test_blocking_conditions_forbid_completion
    with_record do |dir, _plane, record, gate|
      complete_phase!(record, "intake", sha: head(dir))
      path = record.handoff_path(record.control_plane.phase("intake"))
      h = YAML.safe_load_file(path)
      h["blocking"] = ["unresolved_unsafe_ambiguity"]
      File.write(path, YAML.dump(h))
      assert gate.evaluate("intake").failed?
    end
  end

  def test_unknown_commit_sha_fails
    with_record do |_dir, _plane, record, gate|
      complete_phase!(record, "intake", sha: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
      result = gate.evaluate("intake")
      assert_equal :fail, result.checks.find { |c| c.name == "commit_sha recorded" }.outcome
    end
  end

  def test_commit_bound_evidence_goes_stale_when_code_changes
    with_record do |dir, plane, record, gate|
      sha = head(dir)
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: sha) } # intake..verify
      refute gate.evaluate("verify").failed?

      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      result = gate.evaluate("verify")
      assert result.stale?, result.checks.map(&:detail).join("\n")

      sh(dir, "git", "commit", "-qam", "change code")
      assert gate.evaluate("verify").stale?, "committed code changes must still be stale"
    end
  end

  def test_evidence_stays_current_when_only_change_record_changes
    with_record do |dir, plane, record, gate|
      sha = head(dir)
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: sha) }
      sh(dir, "git", "add", ".")
      sh(dir, "git", "commit", "-qm", "record evidence")
      refute gate.evaluate("verify").stale?
    end
  end
end

class GateRemediationTest < Minitest::Test
  include FoundryFixture

  def test_remediation_may_complete_while_an_earlier_phase_is_blocked
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c9", control_plane: plane)
      gate = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
      sha = head(dir)
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: sha) } # through verify
      path = record.handoff_path(plane.phase("evaluate"))
      h = YAML.safe_load_file(path)
      h.merge!("status" => "blocked", "blocking" => ["EVAL-001 failed"])
      File.write(path, YAML.dump(h))
      complete_phase!(record, "remediate", sha: sha)
      result = gate.evaluate("remediate")
      refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
      assert_includes result.checks.find { |c| c.name == "predecessor complete" }.detail, "07-evaluation"
    end
  end

  def test_remediation_still_needs_a_complete_predecessor_when_nothing_is_blocked
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c10", control_plane: plane)
      gate = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
      complete_phase!(record, "remediate", sha: head(dir))
      assert gate.evaluate("remediate").failed?
    end
  end
end
