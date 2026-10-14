# frozen_string_literal: true

require_relative "test_helper"

# changes/factory-readiness: REQ-FR-001 (UTF-8 reads).
class Utf8ReadsTest < Minitest::Test
  include FoundryFixture

  # The process locale decides Encoding.default_external; a C locale makes
  # it US-ASCII, and File.read then yields strings that raise on the first
  # regex match against a non-ASCII byte.
  def with_ascii_default
    saved = Encoding.default_external
    verbose = $VERBOSE
    $VERBOSE = nil
    Encoding.default_external = Encoding::US_ASCII
    yield
  ensure
    Encoding.default_external = saved
    $VERBOSE = verbose
  end

  def with_intake(text)
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      complete_phase!(record, "intake", sha: head(dir))
      File.binwrite(File.join(record.phase_dir(plane.phase("intake")), "request.md"), text)
      yield dir, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def test_gate_and_advisory_read_record_files_as_utf8_whatever_the_locale
    with_intake("# Intake\n\ninit → change new → gate\n".b) do |_dir, record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
        assert_kind_of Array, SoftFoundry::Advisory.new(record).notices
      end
    end
  end

  def test_invalid_bytes_are_scrubbed_not_raised
    with_intake("# Intake\n\xFF\xFE broken TBD here\n".b) do |_dir, _record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        check = result.checks.find { |c| c.name == "no placeholders" }
        assert_equal :fail, check.outcome, "the placeholder is still found after scrubbing"
        assert_includes check.detail, "request.md"
      end
    end
  end

  def test_read_text_returns_utf8_under_any_locale
    Dir.mktmpdir do |dir|
      path = File.join(dir, "t.md")
      File.binwrite(path, "caf\xC3\xA9 \xFF".b)
      with_ascii_default do
        text = SoftFoundry.read_text(path)
        assert_equal Encoding::UTF_8, text.encoding
        assert text.valid_encoding?
        assert_includes text, "café"
      end
    end
  end
end

# REQ-FR-002: the specification is locked on the gated track from the
# commit that recorded it, and evidence produced before a specification
# rerun is stale.
class GatedSpecificationLockTest < Minitest::Test
  include FoundryFixture

  def with_change
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c2", control_plane: plane, branch: "change/c2")
      commit_all(dir, "scaffold c2")
      yield dir, plane, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def check(gate, phase, name) = gate.evaluate(phase).checks.find { |c| c.name == name }

  def test_specification_is_locked_from_the_commit_that_recorded_it
    with_change do |dir, plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      commit_all(dir, "specified")
      lock = head(dir)
      c = check(gate, "specify", "specification locked")
      assert_equal :pass, c.outcome, c.detail
      assert_includes c.detail, lock[0, 12]

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      c = check(gate, "specify", "specification locked")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "requirements.yml"
      assert_includes c.detail, "rerun the specification phase"
      assert gate.evaluate("specify").failed?

      commit_all(dir, "edit the spec after the lock")
      assert_equal :fail, check(gate, "specify", "specification locked").outcome, "a committed edit is still an edit after the lock"
    end
  end

  def test_an_uncommitted_specification_is_not_locked_yet
    with_change do |dir, _plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      c = check(gate, "specify", "specification locked")
      assert_equal :warn, c.outcome
      assert_includes c.detail, "not yet locked"
      refute gate.evaluate("specify").failed?
    end
  end

  def test_evidence_recorded_before_a_specification_rerun_is_stale
    with_change do |dir, plane, record, gate|
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..verify
      commit_all(dir, "through verification")
      refute gate.evaluate("verify").stale?, "evidence recorded with the specification in the same commit is current"
      assert_equal :pass, check(gate, "specify", "specification locked").outcome

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      complete_phase!(record, "specify", sha: head(dir))
      commit_all(dir, "re-record the specification")
      assert_equal :pass, check(gate, "specify", "specification locked").outcome, "the rerun re-binds the lock"
      c = check(gate, "verify", "evidence current")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "specification"
      assert gate.evaluate("verify").stale?
    end
  end
end

# REQ-FR-003: every commit-bound phase completed without `phase run` is
# advised, not only review and judgment.
class FreshContextAdvisoryTest < Minitest::Test
  include FoundryFixture

  def fresh_context!(record, phase_id)
    phase = record.control_plane.phase(phase_id)
    h = record.handoff(phase)
    h["executed_by"] = { "runner" => "soft-foundry phase run", "shell" => "claude", "fresh_context" => true }
    File.write(record.handoff_path(phase), YAML.dump(h))
  end

  def test_verification_evaluation_and_attack_completed_in_session_are_advised
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c3", control_plane: plane)
      plane.phases.take(9).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..attack
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.message.include?("without `soft-foundry phase run`") }
      assert_equal %w[verification evaluation attack], notices.map(&:area)
      assert_includes notices[0].message, "06-verification"
      assert_includes notices[2].message, "08-attack"

      fresh_context!(record, "verify")
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.message.include?("without `soft-foundry phase run`") }
      assert_equal %w[evaluation attack], notices.map(&:area)
    end
  end

  def test_the_evidence_skills_say_they_prefer_a_fresh_session
    %w[verification evaluation adversarial-testing].each do |skill|
      text = SoftFoundry.read_text(File.join(REPO_ROOT, ".ai/skills", skill, "SKILL.md"))
      assert_includes text, "phase run", skill
    end
  end
end

# REQ-FR-007: which phases a change may waive depends on its declared
# risk; review and judgment are never waived; a change closes only with a
# judgment.
class WaiversByRiskTest < Minitest::Test
  include FoundryFixture

  def with_waivers(risk, skipped)
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "w1", control_plane: plane)
      path = File.join(record.dir, "metadata.yml")
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      m["risk"] = risk
      m["skipped_phases"] = skipped.map { |p| { "phase" => p, "rationale" => "harness test" } }
      File.write(path, YAML.dump(m))
      complete_phase!(record, "intake", sha: head(dir))
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("intake")
      yield result.checks.find { |c| c.name == "waivers permitted" }, result
    end
  end

  def test_the_repository_declares_what_each_risk_may_waive
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    assert_equal %w[discover specify threat_model plan attack learn], plane.waivable_by_risk("low")
    assert_equal %w[discover plan], plane.waivable_by_risk("medium")
    assert_equal [], plane.waivable_by_risk("high")
    assert_equal [], plane.waivable_by_risk("TBD")
    assert_equal [], plane.waivable_by_risk(nil)
  end

  def test_a_waiver_the_risk_allows_passes_and_one_it_does_not_fails
    with_waivers("low", %w[threat_model attack]) do |check, result|
      assert_equal :pass, check.outcome, check.detail
      refute result.failed?
    end
    with_waivers("medium", %w[threat_model]) do |check, result|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "threat_model"
      assert_includes check.detail, "medium"
      assert result.failed?
    end
    with_waivers("Low", %w[plan]) { |check, _| assert_equal :pass, check.outcome, "risk is matched case-insensitively" }
  end

  def test_review_and_judgment_are_never_waived
    with_waivers("low", %w[judge]) do |check, _|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "judge"
      assert_includes check.detail, "never"
    end
    with_waivers("high", %w[review]) { |check, _| assert_equal :fail, check.outcome }
  end

  def test_an_unclassified_risk_waives_only_optional_phases
    with_waivers("TBD", %w[discover]) do |check, _|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "risk"
    end
    with_waivers("TBD", %w[document]) { |check, _| assert_equal :pass, check.outcome }
    with_waivers("medium", []) { |check, _| assert_equal :pass, check.outcome }
  end

  def test_check_rejects_a_waiver_rule_naming_judge_review_or_an_unknown_phase
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/workflow.yml")
      wf = YAML.safe_load_file(path)
      wf["waivable_by_risk"] = { "low" => %w[judge nowhere], "medium" => [] }
      File.write(path, YAML.dump(wf))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.select { |f| f.level == :error }.map(&:message)
      assert messages.any? { |m| m.include?("waivable_by_risk") && m.include?("judge") }, messages.inspect
      assert messages.any? { |m| m.include?("waivable_by_risk") && m.include?("nowhere") }, messages.inspect
    end
  end

  def test_change_close_refuses_without_a_completed_judgment_unless_forced
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/w2")
      cli(dir, "change", "new", "w2", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "w2", control_plane: SoftFoundry::ControlPlane.new(dir))
      path = File.join(record.dir, "metadata.yml")
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      m["risk"] = "low"
      m["skipped_phases"] = %w[discover specify threat_model plan attack learn].map { |p| { "phase" => p, "rationale" => "low risk" } }
      File.write(path, YAML.dump(m))
      commit_all(dir, "record w2")
      %w[intake implement verify evaluate review].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "through review")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/w2", "-m", "merge w2")

      refute record.reached_lifecycle_end?, "judgment is never a waived end"
      code, out = cli(dir, "change", "close", "w2")
      assert_equal 1, code, out
      assert_includes out, "14-judgment"
      assert_includes out, "--force"
      refute_equal "closed", record.metadata["status"]

      code, out = cli(dir, "change", "close", "w2", "--force")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
    end
  end
end
