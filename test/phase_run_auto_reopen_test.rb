# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `phase run` on a complete phase whose evidence went stale reopens it
# (source auto) and then runs it; every other refusal still applies first
# and resets nothing.
class PhaseRunAutoReopenTest < Minitest::Test
  include LifecycleFixture

  UPTO_ATTACK = LIFECYCLE - %w[review judge]

  # Every phase through attack complete, then application code changes so
  # the commit-bound evidence of verify onward is stale.
  def with_stale_record(**opts)
    with_lifecycle_record(complete: UPTO_ATTACK, current_phase: "attack", **opts) do |dir, record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed after the evidence")
      yield dir, record
    end
  end

  def run_phase(dir, *args)
    launches = []
    runner = lambda do |launch|
      launches << launch
      0
    end
    code, out, err = run_cli(dir, "phase", "run", *args, runner: runner)
    [code, out + err, launches]
  end

  def test_a_stale_complete_phase_is_reopened_automatically_and_then_run
    with_stale_record do |dir, record|
      stale_sha = record.handoff(record.control_plane.phase("verify"))["commit_sha"]
      code, out, launches = run_phase(dir, "verify", "--shell", "claude")
      assert_equal 0, code, out
      assert_equal 1, launches.size
      assert_includes out, "phase reopen: reopened verify (automatic: evidence stale at #{stale_sha[0, 7]})"
      %w[verify evaluate attack].each { |id| assert_includes out, "phase reopen: reset #{id}" }
      entry = record.metadata["phase_reopenings"].fetch(0)
      assert_equal "auto", entry["source"]
      assert_equal %w[verify evaluate attack], entry["reset"]
      assert_includes entry["reason"], "evidence current"
      assert_includes entry["reason"], stale_sha[0, 7]
      assert_equal "verify", record.metadata["current_phase"]
      assert_includes out, "running verify"
    end
  end

  def test_a_current_phase_is_still_refused_with_no_byte_changed
    with_lifecycle_record(complete: UPTO_ATTACK, current_phase: "attack") do |dir, _record|
      before = tree_bytes(dir)
      code, out, launches = run_phase(dir, "verify", "--shell", "claude")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "06-verification is already complete"
      assert_empty launches
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_a_stale_phase_whose_predecessor_is_incomplete_is_refused_and_nothing_is_reset
    with_stale_record do |dir, record|
      record.update_handoff(record.control_plane.phase("implement")) { |h| h["status"] = "in_progress" }
      commit_all(dir, "implement reopened by hand")
      before = tree_bytes(dir)
      code, out, launches = run_phase(dir, "verify", "--shell", "claude")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "predecessor 05-implementation is in_progress"
      assert_empty launches
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_closed_and_released_records_are_refused_and_nothing_is_reset
    %w[closed released judged].each do |status|
      with_stale_record(status: status) do |dir, _record|
        before = tree_bytes(dir)
        code, out, launches = run_phase(dir, "verify", "--shell", "claude")
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, status
        assert_includes out, "is #{status}"
        assert_empty launches
        assert_equal before, tree_bytes(dir)
      end
    end
  end

  def test_dry_run_says_it_would_reopen_and_writes_nothing
    with_stale_record do |dir, _record|
      before = tree_bytes(dir)
      code, out, launches = run_phase(dir, "verify", "--shell", "claude", "--dry-run")
      assert_equal 0, code
      assert_empty launches
      assert_match(/^phase reopen: would reopen verify \(automatic: evidence stale at [0-9a-f]{7}\)$/, out)
      assert_match(/^phase reopen: would reset attack$/, out)
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_an_auto_reopen_works_inside_a_marked_environment_because_it_runs_before_the_session
    with_stale_record do |dir, record|
      code, out, = run_cli(dir, "phase", "run", "verify", "--shell", "claude", runner: ->(_l) { 0 }, env: { "SOFT_FOUNDRY_PHASE" => "evaluate" })
      assert_equal 0, code, out
      assert_equal "auto", record.metadata["phase_reopenings"].fetch(0)["source"]
    end
  end
end
