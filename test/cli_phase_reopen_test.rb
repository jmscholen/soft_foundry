# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `soft-foundry phase reopen` through the CLI: exit codes, the stable
# one-fact-per-line output, refusals that name the next step, no prompts.
class CliPhaseReopenTest < Minitest::Test
  include LifecycleFixture

  ANSI = /\e\[/

  def test_reopen_prints_one_fact_per_line_and_exits_zero
    with_lifecycle_record(complete: LIFECYCLE - %w[judge]) do |dir, record|
      code, out, err = run_cli(dir, "phase", "reopen", "evaluate", "--reason", "fixture changed")
      assert_equal 0, code, err
      assert_equal ["phase reopen: reopened evaluate (manual)", "phase reopen: reset evaluate", "phase reopen: reset attack", "phase reopen: reset review"], out.lines.map(&:chomp)
      assert_equal "pending", statuses(record)["attack"]
      assert_equal "complete", statuses(record)["verify"]
      refute_match ANSI, out
      assert_predicate out, :ascii_only?
    end
  end

  def test_a_reopened_phase_is_pending_to_the_gate_and_blocks_close_until_redone
    with_lifecycle_record do |dir, _record|
      run_cli(dir, "phase", "reopen", "attack", "--reason", "r")
      code, out, err = run_cli(dir, "gate", "attack")
      assert_includes out + err, "pending", "the gate reports the reopened phase as pending, not complete"
      refute_includes out + err, "complete  PASS"
      code, = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
    end
  end

  def test_change_flag_selects_the_record
    with_lifecycle_record do |dir, record|
      code, _out, err = run_cli(dir, "phase", "reopen", "attack", "--reason", "r", "--change", "c1")
      assert_equal 0, code, err
      assert_equal "pending", statuses(record)["attack"]
    end
  end

  def test_refusals_exit_one_name_the_problem_and_write_nothing
    with_lifecycle_record do |dir, _record|
      before = tree_bytes(dir)
      [
        [%w[reopen polish --reason r], /unknown phase 'polish'/],
        [%w[reopen attack], /--reason is required/],
        [["reopen", "attack", "--reason", ""], /reason/],
        [["reopen", "attack", "--reason", "a" * 501], /501/],
        [["reopen", "attack", "--reason", "x\ny"], /control character/],
        [%w[reopen attack --reason r --bogus], /unknown option/]
      ].each do |args, pattern|
        code, out, err = run_cli(dir, "phase", *args)
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, args.inspect
        assert_match pattern, out + err, args.inspect
      end
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_a_closed_record_is_refused_with_the_next_step
    with_lifecycle_record(status: "closed") do |dir, _record|
      before = tree_bytes(dir)
      code, out, err = run_cli(dir, "phase", "reopen", "attack", "--reason", "r")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/closed/, out + err)
      assert_match(/new change/, out + err)
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_nothing_to_reset_names_the_next_step
    with_lifecycle_record(complete: %w[intake]) do |dir, _record|
      code, out, err = run_cli(dir, "phase", "reopen", "attack", "--reason", "r")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/nothing to reset/, out + err)
    end
  end

  def test_inside_a_phase_session_the_command_is_refused
    with_lifecycle_record do |dir, _record|
      before = tree_bytes(dir)
      code, out, err = run_cli(dir, "phase", "reopen", "attack", "--reason", "r", env: { "SOFT_FOUNDRY_PHASE" => "evaluate" })
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/phase-run session/, out + err)
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_reopening_specify_blocks_close_until_everything_is_redone
    with_lifecycle_record do |dir, _record|
      code, = run_cli(dir, "phase", "reopen", "specify", "--reason", "requirement change")
      assert_equal 0, code
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/14-judgment is pending/, out + err)
    end
  end

  def test_nothing_is_read_from_stdin
    with_lifecycle_record do |dir, _record|
      out = StringIO.new
      err = StringIO.new
      input = Object.new
      def input.method_missing(*) = raise("read from stdin")
      def input.respond_to_missing?(*) = true
      code = with_clean_env { SoftFoundry::CLI.new(%w[phase reopen attack --reason r], out: out, err: err, input: input, root: dir).run }
      assert_equal 0, code, err.string
    end
  end

  def test_a_full_lifecycle_reopen_is_fast
    with_lifecycle_record do |dir, _record|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      code, = run_cli(dir, "phase", "reopen", "intake", "--reason", "everything changed")
      assert_equal 0, code
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1.0
    end
  end

  def test_records_without_the_new_keys_still_check_and_report_status
    with_lifecycle_record do |dir, _record|
      code, = run_cli(dir, "check")
      assert_equal 0, code
      code, = run_cli(dir, "change", "status", "c1")
      assert_includes [0, 2], code
    end
  end
end
