# frozen_string_literal: true

require_relative "test_helper"

# `soft-foundry phase run`: one phase in a fresh coding-shell session,
# refused when the gate would refuse it, stamped with executed_by, gated
# on return, and advised when review or judgment ran without it.
class PhaseRunnerTest < Minitest::Test
  include FoundryFixture

  # A gated change on its own branch with intake through evaluation
  # complete at HEAD, so review is the next runnable phase.
  def with_reviewable_change(slug = "c1")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: SoftFoundry::ControlPlane.new(dir))
      meta = File.join(record.dir, "metadata.yml")
      File.write(meta, File.read(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: evaluate"))
      commit_all(dir, "record")
      %w[intake discover specify threat_model plan implement verify evaluate attack].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases through attack")
      yield dir, record
    end
  end

  # A fake coding shell: records the launch and, if given a block, acts
  # on the repository the way an agent would.
  def run_phase(dir, *args, exit_status: 0, &agent)
    launches = []
    runner = lambda do |launch|
      launches << launch
      agent&.call(launch)
      exit_status
    end
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil, "SOFT_FOUNDRY_BILLING" => nil }) do
      code = SoftFoundry::CLI.new(["phase", "run", *args], out: out, err: err, root: dir, runner: runner).run
    end
    [code, out.string + err.string, launches]
  end

  def complete_handoff!(record, phase_id, dir)
    complete_phase!(record, phase_id, sha: head(dir))
  end

  # --- refusals ------------------------------------------------------------

  def test_refuses_an_exploring_change_a_complete_phase_and_a_pending_predecessor
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/it1")
      cli(dir, "change", "new", "it1", "--track", "iterative")
      commit_all(dir, "record")
      code, out, launches = run_phase(dir, "implement")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "is exploring"
      assert_empty launches
    end
    with_reviewable_change do |dir, _record|
      code, out, launches = run_phase(dir, "verify")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "06-verification is already complete"
      assert_empty launches
      code, out, launches = run_phase(dir, "learn")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "predecessor 14-judgment is pending"
      assert_empty launches
      code, out, = run_phase(dir, "polish")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "unknown phase 'polish'"
    end
  end

  # --- dry run and prompt ------------------------------------------------------

  def test_dry_run_prints_the_command_and_the_prompt_without_launching
    with_reviewable_change do |dir, record|
      code, out, launches = run_phase(dir, "review", "--dry-run")
      assert_equal 0, code, out
      assert_empty launches
      assert_includes out, "would run review of c1 with: claude -p <prompt>"
      assert_includes out, "Phase: review (changes/c1/13-review/)"
      assert_includes out, "Skill: review (profile reasoning_high)"
      assert_includes out, ".ai/skills/review/SKILL.md"
      assert_includes out, "Do not edit executed_by; the runner writes it"
      assert_includes out, "! warn guard: the guard hook is not installed for claude"
      assert_nil record.handoff(record.control_plane.phase("review"))["executed_by"], "a dry run stamps nothing"
      assert_equal "evaluate", record.metadata["current_phase"]

      code, out, = run_phase(dir, "review", "--dry-run", "--shell", "codex", "--", "--full-auto")
      assert_equal 0, code, out
      assert_includes out, "would run review of c1 with: codex exec --full-auto <prompt>"
    end
  end

  def test_dry_run_is_silent_about_the_guard_once_it_is_installed
    with_reviewable_change do |dir, _record|
      cli(dir, "hooks", "install", "--claude")
      _, out, = run_phase(dir, "review", "--dry-run")
      refute_includes out, "guard hook is not installed"
    end
  end

  # --- a run ---------------------------------------------------------------------

  def test_run_moves_current_phase_stamps_executed_by_and_gates_the_result
    with_reviewable_change do |dir, record|
      phase = record.control_plane.phase("review")
      code, out, launches = run_phase(dir, "review") { |_launch| complete_handoff!(record, "review", dir) }
      assert_equal 0, code, out
      assert_equal 1, launches.size
      assert_equal "claude", launches.first.executable
      assert_equal ["-p", launches.first.prompt], launches.first.args
      assert_includes out, "running review of c1 in a fresh claude session (review skill)"
      assert_includes out, "claude exited 0"
      assert_includes out, "13-review  complete  PASS"

      assert_equal "review", record.metadata["current_phase"]
      executed = record.handoff(phase)["executed_by"]
      assert_equal "soft-foundry phase run", executed["runner"]
      assert_equal "claude", executed["shell"]
      assert_equal true, executed["fresh_context"]
      assert_equal 0, executed["exit_status"]
      assert executed["started_at"] && executed["finished_at"]
      assert_equal "evaluate", executed["previous_phase"]

      # A review run this way carries no fresh-context advisory.
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.message.include?("fresh-context") }
      assert_empty notices
    end
  end

  def test_run_leaves_the_attempt_in_the_record_when_the_session_fails
    with_reviewable_change do |dir, record|
      phase = record.control_plane.phase("review")
      code, out, = run_phase(dir, "review", exit_status: 3)
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "claude exited 3"
      h = record.handoff(phase)
      assert_equal "in_progress", h["status"], "begin! moved pending to in_progress so the attempt is visible"
      assert_equal 3, h.dig("executed_by", "exit_status")
      assert_includes out, "13-review  in_progress"
    end
  end

  def test_run_reports_a_failing_gate_with_exit_2
    with_reviewable_change do |dir, record|
      code, out, = run_phase(dir, "review") { |_launch| complete_phase!(record, "review", sha: head(dir), fill: false) }
      assert_equal 2, code
      assert_includes out, "13-review  complete  FAIL"
      assert_includes out, "TBD remains in"
    end
  end

  # --- advisory ------------------------------------------------------------------

  def test_review_and_judgment_completed_without_the_runner_are_advised
    with_reviewable_change do |dir, record|
      complete_handoff!(record, "review", dir)
      notices = SoftFoundry::Advisory.new(record).notices
      review = notices.find { |n| n.area == "review" }
      assert review, notices.map(&:message).inspect
      assert_includes review.message, "13-review) was completed without `soft-foundry phase run`"
      assert_nil notices.find { |n| n.area == "judgment" }, "judgment is still pending"

      complete_handoff!(record, "judge", dir)
      notices = SoftFoundry::Advisory.new(record).notices
      assert notices.find { |n| n.area == "judgment" && n.message.include?("without `soft-foundry phase run`") }

      _, out = cli(dir, "gate", "review")
      assert_includes out, "! warn review: independent review (13-review) was completed without"
    end
  end

  def test_template_handoff_carries_executed_by_as_null
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c9")
      record = SoftFoundry::ChangeRecord.new(dir, "c9", control_plane: SoftFoundry::ControlPlane.new(dir))
      h = record.handoff(record.control_plane.phase("intake"))
      assert h.key?("executed_by")
      assert_nil h["executed_by"]
    end
  end
end
