# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Command behaviour gate hardening changes (REQ-016 to REQ-019, REQ-022,
# REQ-023): the gate's exit on a phase that is not complete, the close
# refusal on a BLOCKED or REJECTED verdict, equals-form options, a named
# malformed field in the summary, and the small residuals closed here.
class GateHardeningCliTest < Minitest::Test
  include FinishedFixture

  def meta(dir, slug) = YAML.safe_load_file(File.join(dir, "changes", slug, "metadata.yml"), permitted_classes: [Time])

  # --- gate exit codes (REQ-016) ---

  def test_gate_on_pending_phase_exits_3_and_all_exits_0
    with_lifecycle_record(complete: LIFECYCLE - %w[judge]) do |dir, _record|
      run_cli(dir, "phase", "reopen", "verify", "--reason", "redo")
      code, out, = run_cli(dir, "gate", "verify")
      assert_equal 3, code
      assert_includes out, "06-verification  pending  SKIP"
      code, = run_cli(dir, "gate", "all")
      assert_equal 0, code
      code, = run_cli(dir, "gate", "implement")
      assert_equal 0, code, "a complete, passing phase still exits 0"
    end
  end

  # --- close refuses a BLOCKED or REJECTED verdict (REQ-017) ---

  def test_refuses_blocked_without_force
    with_finished_record(outcome: "BLOCKED", merge: true) do |dir, record|
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes err, "BLOCKED"
      assert_includes err, "remediate"
      refute_equal "closed", record.metadata["status"]
      code, out, err = run_cli(dir, "change", "close", "c1", "--force")
      assert_equal 0, code, out + err
      assert_equal "closed", record.metadata["status"]
    end
  end

  def test_refuses_rejected_naming_intake
    with_finished_record(outcome: "REJECTED", merge: true) do |dir, _record|
      code, _out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes err, "REJECTED"
      assert_includes err, "intake"
    end
  end

  def test_closes_approved_with_residual_risk
    with_finished_record(outcome: "APPROVED_WITH_RESIDUAL_RISK", merge: true) do |dir, record|
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal 0, code, out + err
      assert_equal "closed", record.metadata["status"]
    end
  end

  # --- equals-form options and repeated flags (REQ-018) ---

  def test_equals_form_and_twice
    with_fixture_repo do |dir|
      code, out, err = run_cli(dir, "change", "new", "demo", "--type=fix", "--risk=low", "--track=gated")
      assert_equal 0, code, out + err
      assert_equal "fix", meta(dir, "demo")["type"]
      assert_equal "low", meta(dir, "demo")["risk"]
      assert_equal "gated", meta(dir, "demo")["track"]
      code, out, err = run_cli(dir, "change", "new", "demo2", "--type", "fix", "--type", "docs")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "--type given twice"
      refute File.exist?(File.join(dir, "changes", "demo2"))
      code, out, err = run_cli(dir, "phase", "run", "verify", "--change", "demo", "--env=X=1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out + err, "--env takes its value as the next argument"
    end
  end

  # --- summary names a malformed field (REQ-019) and refuses a symlink (REQ-034) ---

  def test_malformed_blocking_named
    with_lifecycle_record(complete: LIFECYCLE.take(7), current_phase: "evaluate") do |dir, record|
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["blocking"] = "text" }
      record.update_handoff(record.control_plane.phase("implement")) { |h| h["findings"] = { "id" => "x" } }
      code, out, err = run_cli(dir, "change", "summary", "c1")
      assert_equal 0, code, err
      assert_includes out.lines.map(&:chomp), "blocking: malformed (06-verification: String, expected a list)"
      assert_includes out.lines.map(&:chomp), "findings: malformed (05-implementation: Hash, expected a list)"
      refute_includes out, "blocking: none"
    end
  end

  def test_summary_refuses_symlinked_handoff
    with_lifecycle_record(complete: LIFECYCLE.take(7), current_phase: "evaluate") do |dir, record|
      path = record.handoff_path(record.control_plane.phase("intake"))
      File.rename(path, "#{path}.real")
      File.symlink("#{path}.real", path)
      code, out, err = run_cli(dir, "change", "summary", "c1")
      assert_equal 0, code, err
      assert(out.lines.any? { |l| l.start_with?("note: intake") && l.include?("symlink") }, out)
      assert_includes out, "phase-status: intake unreadable"
    end
  end

  # --- reopen clears started_at (REQ-022) ---

  def test_reopen_clears_started_at
    with_lifecycle_record(complete: LIFECYCLE - %w[judge]) do |dir, record|
      verify = record.control_plane.phase("verify")
      record.update_handoff(verify) { |h| h["started_at"] = "2026-01-01T00:00:00Z" }
      code, _out, err = run_cli(dir, "phase", "reopen", "verify", "--reason", "x")
      assert_equal 0, code, err
      assert_nil record.handoff(verify)["started_at"]
    end
  end

  # --- Unicode-blank discharged_at is open (REQ-022) ---

  def test_unicode_blank_discharged_at_is_open
    [" ", " ", " ", " \t "].each do |blank|
      refute SoftFoundry::ChangeRecord.discharged?({ "id" => "A", "discharged_at" => blank }), blank.dump
    end
    assert SoftFoundry::ChangeRecord.discharged?({ "id" => "A", "discharged_at" => "2026-10-29T00:00:00Z" })
    with_finished_record(merge: true) do |dir, record|
      run_cli(dir, "change", "release", "c1", "--item", "GOLIVE-1=watch it")
      record.update_metadata { |m| m["release"]["items"].first["discharged_at"] = " " }
      code, _out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes err, "GOLIVE-1"
      _code, out, = run_cli(dir, "change", "status", "c1")
      assert_includes out, "GOLIVE-1"
    end
  end

  # --- ps names every phase of a parallel run (REQ-022) ---

  def test_ps_reports_every_parallel_phase
    processes = SoftFoundry::Processes.allocate
    assert_equal "evaluate,attack", processes.send(:phase_of, "phase run", %w[phase run evaluate attack --parallel])
    assert_equal "verify", processes.send(:phase_of, "phase run", %w[phase run verify --shell claude])
    assert_nil processes.send(:phase_of, "phase run", %w[phase run ../x])
  end

  # --- check compares forced_by_risk keys (REQ-023) ---

  def test_forced_by_risk_keys_checked
    with_fixture_repo do |dir|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).sub(/^    high: gated/, "    hihg: gated"))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      assert findings.any? { |f| f.message.include?("forced_by_risk") && f.message.include?("hihg") }, findings.map(&:message).inspect
    end
  end

  # --- a failed blocked-mark says what to do next (REQ-023) ---

  def test_failed_blocked_mark_names_the_next_step
    with_lifecycle_record(complete: LIFECYCLE.take(9), current_phase: "review") do |dir, record|
      out = StringIO.new
      err = StringIO.new
      cli = SoftFoundry::CLI.new([], out: out, err: err, root: dir)
      failing = Object.new
      def failing.mark_blocked!(_phase) = raise(SoftFoundry::TargetError, "lock held by another process")
      refute cli.send(:mark_blocked, failing, record.control_plane.phase("review"))
      assert_includes err.string, "warn: could not mark review blocked: lock held by another process"
      assert_includes err.string, "left as written"
      assert_includes err.string, "redo the phase"
    end
  end
end
