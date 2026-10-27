# frozen_string_literal: true

require_relative "lifecycle_fixture"

# A session that leaves a handoff complete while listing blocking items is
# marked blocked by the runner, on every run path.
class PhaseRunBlockedMarkingTest < Minitest::Test
  include LifecycleFixture

  UPTO_PLAN = %w[intake discover specify threat_model plan].freeze

  # A fake session that leaves the handoff as the agent would.
  def finishing(record, phase_id, blocking:)
    phase = record.control_plane.phase(phase_id)
    lambda do |_launch|
      path = record.handoff_path(phase)
      h = YAML.safe_load_file(path)
      h.merge!("status" => "complete", "blocking" => blocking, "completed_at" => "2026-10-01T00:00:00Z")
      File.write(path, YAML.dump(h))
      0
    end
  end

  def test_complete_with_blocking_is_marked_blocked
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      items = ["needs a human decision", "ci red"]
      code, out, err = run_cli(dir, "phase", "run", "implement", "--shell", "claude", runner: finishing(record, "implement", blocking: items))
      h = record.handoff(record.control_plane.phase("implement"))
      assert_equal "blocked", h["status"]
      assert_equal items, h["blocking"]
      assert_includes h["notes"], "blocked"
      assert_includes out + err, "blocked: implement has 2 blocking item(s)"
      refute_equal 0, code
    end
  end

  def test_complete_with_empty_blocking_is_untouched
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      run_cli(dir, "phase", "run", "implement", "--shell", "claude", runner: finishing(record, "implement", blocking: []))
      assert_equal "complete", record.handoff(record.control_plane.phase("implement"))["status"]
      refute_includes(run_cli(dir, "gate", "implement")[1], "blocked:")
    end
  end

  def test_only_the_finished_phases_handoff_changes
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      before = tree_bytes(dir)
      run_cli(dir, "phase", "run", "implement", "--shell", "claude", runner: finishing(record, "implement", blocking: ["x"]))
      changed = tree_bytes(dir).reject { |k, v| before[k] == v }.keys
      assert_equal ["changes/c1/05-implementation/handoff.yml"], changed
    end
  end

  def test_a_stale_phase_reopened_automatically_is_marked_too
    with_lifecycle_record(complete: LIFECYCLE - %w[evaluate attack review judge], current_phase: "verify") do |dir, record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed")
      code, out, err = run_cli(dir, "phase", "run", "verify", "--shell", "claude", runner: finishing(record, "verify", blocking: ["y"]))
      assert_equal "blocked", record.handoff(record.control_plane.phase("verify"))["status"]
      assert_includes out + err, "blocked: verify has 1 blocking item(s)"
      refute_equal 0, code
    end
  end

  def test_the_gate_still_fails_a_hand_edited_complete_handoff_with_blocking
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      record.update_handoff(record.control_plane.phase("plan")) { |h| h["blocking"] = ["still open"] }
      code, out, = run_cli(dir, "gate", "plan")
      refute_equal 0, code
      assert_includes out, "no blocking conditions"
    end
  end

  def test_a_failed_write_raises_for_the_caller_to_warn_and_leaves_the_handoff
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      phase = record.control_plane.phase("implement")
      path = record.handoff_path(phase)
      File.write(path, YAML.dump(YAML.safe_load_file(path).merge("status" => "complete", "blocking" => ["x"])))
      before = File.binread(path)
      busy = record.dup
      busy.define_singleton_method(:update_handoff) { |*| raise SoftFoundry::TargetError, "lock busy" }
      runner = SoftFoundry::PhaseRunner.new(dir, plane: record.control_plane, git: SoftFoundry::Git.new(dir), record: busy)
      assert_raises(SoftFoundry::TargetError) { runner.mark_blocked!(phase) }
      assert_equal before, File.binread(path)
    end
  end

  def test_mark_blocked_reports_the_count_and_nothing_for_a_clean_handoff
    with_lifecycle_record(complete: UPTO_PLAN, current_phase: "plan") do |dir, record|
      phase = record.control_plane.phase("plan")
      runner = SoftFoundry::PhaseRunner.new(dir, plane: record.control_plane, git: SoftFoundry::Git.new(dir), record: record)
      assert_nil runner.mark_blocked!(phase)
      record.update_handoff(phase) { |h| h["blocking"] = %w[a b c] }
      assert_equal 3, runner.mark_blocked!(phase)
      assert_equal %w[a b c], record.handoff(phase)["blocking"]
    end
  end
end
