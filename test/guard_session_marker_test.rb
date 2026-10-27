# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The guard resolves the active skill from the session marker the runner
# sets (SOFT_FOUNDRY_PHASE), so concurrent sessions are each checked
# against their own skill whatever current_phase says (THREAT-001).
class GuardSessionMarkerTest < Minitest::Test
  include LifecycleFixture

  EVAL_NOTES = "changes/c1/07-evaluation/results.md"
  ATTACK_NOTES = "changes/c1/08-attack/results.md"

  def with_parked_change(current_phase: "implement", isolated: true, status: "in_progress")
    with_lifecycle_record(complete: [], status: status, current_phase: current_phase) do |dir, record|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).gsub(/^isolated_phases:.*\n/, "") + (isolated ? "\nisolated_phases: [evaluate, attack]\n" : ""))
      commit_all(dir, "isolated phases")
      yield dir, record
    end
  end

  def guard(dir, env) = SoftFoundry::Guard.new(dir, env: env)

  def write(path) = { "file_path" => path }

  def test_the_marker_chooses_the_skill_over_current_phase
    with_parked_change(current_phase: "implement") do |dir, _record|
      g = guard(dir, "SOFT_FOUNDRY_PHASE" => "evaluate")
      assert g.decide("Edit", write("lib/app.rb")).violation?, "evaluation may not write application code, even though current_phase is implement"
      assert_equal :allow, g.decide("Edit", write(EVAL_NOTES)).outcome
      assert g.decide("Edit", write(ATTACK_NOTES)).violation?
      assert_equal :allow, guard(dir, {}).decide("Edit", write("lib/app.rb")).outcome, "no marker: current_phase decides, as before"
    end
  end

  def test_two_concurrent_sessions_are_each_held_to_their_own_skill
    with_parked_change(current_phase: "verify") do |dir, _record|
      evaluating = guard(dir, "SOFT_FOUNDRY_PHASE" => "evaluate", "SOFT_FOUNDRY_PARALLEL" => "1")
      attacking = guard(dir, "SOFT_FOUNDRY_PHASE" => "attack", "SOFT_FOUNDRY_PARALLEL" => "1")
      assert_equal :allow, evaluating.decide("Write", write(EVAL_NOTES)).outcome
      assert evaluating.decide("Write", write(ATTACK_NOTES)).violation?
      assert_equal :allow, attacking.decide("Write", write(ATTACK_NOTES)).outcome
      assert attacking.decide("Write", write(EVAL_NOTES)).violation?
    end
  end

  def test_bad_markers_are_violations_never_a_silent_fallback
    with_parked_change(current_phase: "implement") do |dir, _record|
      ["", "Evaluate", "EVALUATE", "../x", "evaluate ", "nonsense", "eval-ate", "evaluate\n", "intake/../x"].each do |marker|
        d = guard(dir, "SOFT_FOUNDRY_PHASE" => marker).decide("Edit", write("lib/app.rb"))
        assert d.violation?, "marker #{marker.inspect} must not fall back to current_phase"
        assert_includes d.reason, "SOFT_FOUNDRY_PHASE"
      end
    end
  end

  def test_a_non_isolated_marker_in_a_parallel_run_is_a_violation
    with_parked_change do |dir, _record|
      d = guard(dir, "SOFT_FOUNDRY_PHASE" => "implement", "SOFT_FOUNDRY_PARALLEL" => "1").decide("Edit", write("lib/app.rb"))
      assert d.violation?
      assert_includes d.reason, "isolated_phases"
      assert_equal :allow, guard(dir, "SOFT_FOUNDRY_PHASE" => "implement").decide("Edit", write("lib/app.rb")).outcome, "a single-phase run may name any phase"
    end
  end

  def test_a_parallel_marker_without_a_declared_list_is_a_violation
    with_parked_change(isolated: false) do |dir, _record|
      d = guard(dir, "SOFT_FOUNDRY_PHASE" => "evaluate", "SOFT_FOUNDRY_PARALLEL" => "1").decide("Write", write(EVAL_NOTES))
      assert d.violation?
    end
  end

  def test_the_status_check_still_comes_first
    with_parked_change(status: "closed") do |dir, _record|
      assert_equal :allow, guard(dir, "SOFT_FOUNDRY_PHASE" => "evaluate").decide("Edit", write("lib/app.rb")).outcome
    end
  end

  def test_a_released_record_resolves_no_skill
    with_parked_change(status: "released") do |dir, _record|
      d = guard(dir, "SOFT_FOUNDRY_PHASE" => "evaluate").decide("Edit", write("lib/app.rb"))
      assert_equal :allow, d.outcome
      assert_includes d.reason, "released"
    end
  end

  def test_enforcement_mode_decides_what_the_shell_is_told
    with_parked_change(current_phase: "implement") do |dir, _record|
      payload = JSON.generate("tool_name" => "Edit", "tool_input" => { "file_path" => "lib/app.rb" })
      { "block" => 2, "warn" => 0 }.each do |mode, expected|
        out = StringIO.new
        err = StringIO.new
        code = with_env({ "SOFT_FOUNDRY_GUARD" => mode, "SOFT_FOUNDRY_PHASE" => "Evaluate" }) do
          SoftFoundry::CLI.new(["guard"], out: out, err: err, input: StringIO.new(payload), root: dir).run
        end
        assert_equal expected, code, mode
        assert_includes out.string + err.string, "SOFT_FOUNDRY_PHASE"
      end
    end
  end

  def test_without_a_marker_behaviour_is_unchanged
    with_parked_change(current_phase: "evaluate") do |dir, _record|
      g = guard(dir, {})
      assert g.decide("Edit", write("lib/app.rb")).violation?
      assert_equal :allow, g.decide("Edit", write(EVAL_NOTES)).outcome
    end
  end
end
