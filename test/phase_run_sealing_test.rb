# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `phase run` seals the phase it ran when the gate passes (REQ-005): a
# single run after the session returns, a parallel run for each passed
# phase in lifecycle order, and never a phase left in progress or blocked.
class PhaseRunSealingTest < Minitest::Test
  include LifecycleFixture

  THROUGH_ATTACK = LIFECYCLE.take(9)
  THROUGH_VERIFY = LIFECYCLE.take(7)

  def log(dir) = sh(dir, "git", "log", "--format=%s", "-n", "4").lines.map(&:chomp)

  def run_phase(dir, *args, exit_status: 0, &agent)
    launches = []
    runner = lambda do |launch|
      launches << launch
      agent&.call(launch)
      exit_status
    end
    code, out, err = run_cli(dir, "phase", "run", *args, runner: runner)
    [code, out + err, launches]
  end

  def run_parallel(dir, *args, &session)
    launches = Queue.new
    runner = lambda do |launch|
      launches << launch
      session ? session.call(launch) : 0
    end
    code, out, err = run_cli(dir, "phase", "run", *args, runner: runner)
    [code, out + err]
  end

  def with_isolated(**opts)
    with_lifecycle_record(complete: [], current_phase: "verify", **opts) do |dir, record|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).gsub(/^isolated_phases:.*\n/, "") + "\nisolated_phases: [evaluate, attack]\n")
      commit_all(dir, "isolated phases")
      THROUGH_VERIFY.each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases complete")
      yield dir, record
    end
  end

  def test_run_seals_passing_phase
    with_lifecycle_record(complete: THROUGH_ATTACK, current_phase: "review") do |dir, record|
      before = head(dir)
      code, out, = run_phase(dir, "review", "--shell", "claude") do |_launch|
        complete_phase!(record, "review", sha: before, runner: false)
      end
      assert_equal 0, code, out
      assert_equal "Record c1 review", log(dir).first
      refute_equal before, head(dir)
      handoff = record.handoff(record.control_plane.phase("review"))
      assert_equal 0, handoff.dig("executed_by", "exit_status")
      assert handoff.dig("executed_by", "finished_at")
      assert_includes out, "sealed 13-review"
    end
  end

  def test_run_does_not_seal_in_progress_handoff
    with_lifecycle_record(complete: THROUGH_ATTACK, current_phase: "review") do |dir, _record|
      before = head(dir)
      code, out, = run_phase(dir, "review", "--shell", "claude")
      assert_equal 2, code, out
      assert_equal before, head(dir)
      assert_includes out, "not sealed"
    end
  end

  def test_prompt_says_runner_seals
    with_lifecycle_record(complete: THROUGH_ATTACK, current_phase: "review") do |dir, record|
      runner = SoftFoundry::PhaseRunner.new(dir, plane: record.control_plane, git: SoftFoundry::Git.new(dir), record: record)
      prompt = runner.prompt(record.control_plane.phase("review"))
      assert_includes prompt, "seal"
      assert_includes prompt, "do not commit"
      parallel = runner.prompt(record.control_plane.phase("evaluate"), parallel_head: head(dir))
      assert_includes parallel, "do not commit anything"
    end
  end

  def test_parallel_seals_passed_and_exits_2_on_blocked
    with_isolated do |dir, record|
      head_before = head(dir)
      code, out = run_parallel(dir, "evaluate", "attack", "--parallel") do |launch|
        phase = launch.env["SOFT_FOUNDRY_PHASE"]
        if phase == "evaluate"
          complete_phase!(record, "evaluate", sha: head_before, runner: false)
        else
          record.update_handoff(record.control_plane.phase("attack")) { |h| h.merge!("status" => "blocked", "blocking" => ["needs a person"]) }
        end
        0
      end
      assert_equal 2, code, out
      assert_equal "Record c1 evaluate", log(dir).first
      assert_includes out, "sealed 07-evaluation"
      assert_includes out, "attack"
      assert_includes out, "not sealed"
      assert_equal "blocked", record.phase_status(record.control_plane.phase("attack"))
    end
  end

  def test_parallel_seals_in_lifecycle_order
    with_isolated do |dir, record|
      head_before = head(dir)
      code, out = run_parallel(dir, "attack", "evaluate", "--parallel") do |launch|
        complete_phase!(record, launch.env["SOFT_FOUNDRY_PHASE"], sha: head_before, runner: false)
        0
      end
      assert_equal 0, code, out
      assert_equal ["Record c1 attack", "Record c1 evaluate"], log(dir).first(2)
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("attack")
      %w[predecessor\ complete commit\ lineage].each do |name|
        c = result.checks.find { |x| x.name == name }
        assert_equal :pass, c.outcome, "#{name}: #{c.detail}"
      end
    end
  end

  def test_env_value_never_printed_by_sealing
    with_isolated do |dir, record|
      head_before = head(dir)
      code, out = run_parallel(dir, "evaluate", "attack", "--parallel", "--env", "SECRET=hunter2") do |launch|
        phase = launch.env["SOFT_FOUNDRY_PHASE"]
        complete_phase!(record, phase, sha: head_before, runner: false) if phase == "evaluate"
        phase == "evaluate" ? 0 : 1
      end
      refute_equal 0, code
      refute_includes out, "hunter2"
      assert_includes out, "sealed 07-evaluation"
    end
  end
end
