# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `phase run <phase> <phase>... --parallel`: isolated phases run at once in
# their own sessions, refusals start nothing, the record survives
# concurrent updates, and an --env value never leaves the child's
# environment.
class PhaseRunParallelTest < Minitest::Test
  include LifecycleFixture

  EXE = File.join(FoundryFixture::REPO_ROOT, "exe", "soft-foundry")
  THROUGH_VERIFY = LIFECYCLE.take(7)

  # Through verification complete, the workflow declaring evaluate and
  # attack isolated, evaluate and attack pending.
  def with_parallel_record(complete: THROUGH_VERIFY, isolated: "[evaluate, attack]", **opts)
    with_lifecycle_record(complete: [], current_phase: "verify", **opts) do |dir, record|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).gsub(/^isolated_phases:.*\n/, "") + (isolated ? "\nisolated_phases: #{isolated}\n" : ""))
      commit_all(dir, "isolated phases")
      complete.each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases complete")
      yield dir, record
    end
  end

  # Runs the command with a stand-in for the coding shell: the block gets
  # each launch (from its own thread) and returns an exit status.
  def run_parallel(dir, *args, &session)
    launches = Queue.new
    runner = lambda do |launch|
      launches << launch
      session ? session.call(launch) : 0
    end
    code, out, err = run_cli(dir, "phase", "run", *args, runner: runner)
    list = []
    list << launches.pop until launches.empty?
    [code, out + err, list.sort_by { |l| l.env["SOFT_FOUNDRY_PHASE"] }]
  end

  def phase_of(launch) = launch.env["SOFT_FOUNDRY_PHASE"]

  def complete!(record, dir, id) = complete_phase!(record, id, sha: head(dir))

  # --- concurrency and results ------------------------------------------------

  def test_both_sessions_run_at_the_same_time_each_with_its_own_phase
    with_parallel_record do |dir, record|
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        sleep 0.6
        complete!(record, dir, phase_of(launch))
        0
      end
      assert_equal 0, code, out
      assert_equal %w[attack evaluate], launches.map { |l| phase_of(l) }.sort
      assert_equal "complete", record.phase_status(record.control_plane.phase("evaluate"))
      assert_equal "complete", record.phase_status(record.control_plane.phase("attack"))
      assert(launches.all? { |l| l.env["SOFT_FOUNDRY_PARALLEL"] == "1" })
      assert(launches.all? { |l| l.prompt.include?(l.env["SOFT_FOUNDRY_PHASE"] == "evaluate" ? ".ai/skills/evaluation/SKILL.md" : ".ai/skills/adversarial-testing/SKILL.md") })
      assert(launches.none? { |l| l.prompt.include?("adversarial-testing") && phase_of(l) == "evaluate" }, "each session sees only its own skill")
    end
  end

  def test_a_session_leaving_complete_with_blocking_is_marked_blocked_and_the_run_exits_nonzero
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        id = phase_of(launch)
        complete!(record, dir, id)
        if id == "evaluate"
          path = record.handoff_path(record.control_plane.phase("evaluate"))
          h = YAML.safe_load_file(path)
          File.write(path, YAML.dump(h.merge("status" => "complete", "blocking" => ["needs a person"])))
        end
        0
      end
      assert_equal 2, code, out
      assert_equal "blocked", record.phase_status(record.control_plane.phase("evaluate"))
      assert_includes out, "blocked: evaluate has 1 blocking item(s)"
      assert_includes out, "phase evaluate: fail"
    end
  end

  def test_the_sessions_overlap_in_time
    with_parallel_record do |dir, _record|
      barrier = Queue.new
      overlap = Queue.new
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |_launch|
        barrier << :in
        # Each waits for the other to have started; a sequential run would never get here.
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
        sleep 0.02 until barrier.size >= 2 || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        overlap << (barrier.size >= 2)
        0
      end
      assert_equal 0, code, out
      assert_equal [true, true], [overlap.pop, overlap.pop]
    end
  end

  def test_one_line_per_phase_in_lifecycle_order_and_a_summary
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "attack", "evaluate", "--parallel", "--shell", "claude") do |launch|
        complete!(record, dir, phase_of(launch))
        0
      end
      assert_equal 0, code, out
      lines = out.lines.map(&:chomp)
      assert_equal ["phase evaluate: pass", "phase attack: pass"], lines.grep(/\Aphase (evaluate|attack): (pass|fail)\z/)
      assert_includes lines, "parallel: 2 phases run, 2 passed, 0 failed"
      assert(lines.grep(/\A(phase |parallel:|warn:)/).all?(&:ascii_only?), "new lines carry no non-ASCII")
    end
  end

  def test_one_failing_session_does_not_stop_the_other_and_the_exit_is_non_zero
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        id = phase_of(launch)
        if id == "attack"
          1
        else
          sleep 0.3
          complete!(record, dir, id)
          0
        end
      end
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out
      assert_includes out, "phase evaluate: pass"
      assert_includes out, "phase attack: fail"
      assert_equal "complete", record.phase_status(record.control_plane.phase("evaluate"))
      assert_includes out, "parallel: 2 phases run, 1 passed, 1 failed"
    end
  end

  def test_a_session_that_raises_fails_only_its_own_phase
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        raise "claude is not installed or not on PATH" if phase_of(launch) == "evaluate"

        complete!(record, dir, "attack")
        0
      end
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out
      assert_includes out, "phase evaluate: fail"
      assert_includes out, "phase evaluate: could not run: claude is not installed or not on PATH"
      assert_equal "in_progress", record.phase_status(record.control_plane.phase("evaluate"))
      handoff = record.handoff(record.control_plane.phase("evaluate"))
      assert_equal 1, handoff.dig("executed_by", "exit_status")
    end
  end

  def test_a_missing_shell_executable_fails_that_phase_only
    with_parallel_record do |dir, _record|
      Dir.mktmpdir do |empty|
        out = StringIO.new
        err = StringIO.new
        code = with_clean_env("PATH" => "#{empty}:/usr/bin:/bin") { SoftFoundry::CLI.new(%w[phase run evaluate attack --parallel --shell claude], out: out, err: err, root: dir).run }
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code
        text = out.string + err.string
        assert_includes text, "phase evaluate: fail"
        assert_includes text, "phase attack: fail"
        assert_includes text, "claude is not installed or not on PATH"
      end
    end
  end

  # --- refusals start nothing and write nothing ----------------------------------

  def refuse(dir, *args, pattern)
    before = tree_bytes(dir)
    code, out, launches = run_parallel(dir, *args)
    assert_equal SoftFoundry::CLI::EXIT_TARGET, code, "#{args.inspect}: #{out}"
    assert_match pattern, out, args.inspect
    assert_empty launches, args.inspect
    assert_equal before, tree_bytes(dir), args.inspect
  end

  def test_every_pre_flight_refusal_starts_nothing_and_says_what_to_do
    with_parallel_record do |dir, _record|
      refuse(dir, "evaluate", "verify", "--parallel", /verify is not in isolated_phases.*evaluate, attack/)
      refuse(dir, "evaluate", "evaluate", "--parallel", /evaluate is named twice/)
      refuse(dir, "evaluate", "--parallel", /two or more phases/)
      refuse(dir, "evaluate", "Attack", "--parallel", /unknown phase 'Attack'/)
      refuse(dir, "evaluate", "attack", "--parallel", "--env", "lower=x", /lower/)
      refuse(dir, "evaluate", "attack", "--parallel", "--env", "SOFT_FOUNDRY_PHASE=x", /SOFT_FOUNDRY_PHASE.*reserved/)
      refuse(dir, "evaluate", "attack", "--parallel", "--env", "NOEQUALS", /NAME=VALUE/)
      refuse(dir, "evaluate", "attack", "--parallel", "--env", "A=1", "--env", "A=2", /A is given twice/)
      refuse(dir, "evaluate", "attack", "--parallel", "--panel", "claude,codex", /--panel/)
      refuse(dir, "evaluate", "attack", "--parallel", "--bogus", /unknown option/)
    end
  end

  def test_a_workflow_without_isolated_phases_refuses_and_names_the_key
    with_parallel_record(isolated: nil) do |dir, _record|
      refuse(dir, "evaluate", "attack", "--parallel", /no isolated_phases declared/)
    end
  end

  def test_a_phase_a_single_run_would_refuse_refuses_the_whole_run
    with_parallel_record(complete: THROUGH_VERIFY - %w[verify]) do |dir, _record|
      refuse(dir, "evaluate", "attack", "--parallel", /cannot run evaluate: .*predecessor 06-verification is pending/)
    end
    with_parallel_record(status: "closed") do |dir, _record|
      refuse(dir, "evaluate", "attack", "--parallel", /is closed/)
    end
    with_parallel_record(status: "released") do |dir, _record|
      refuse(dir, "evaluate", "attack", "--parallel", /is released/)
    end
  end

  def test_attack_alone_is_refused_for_its_predecessor_but_accepted_beside_evaluate
    with_parallel_record do |dir, _record|
      refuse(dir, "attack", "--shell", "claude", /predecessor 07-evaluation is pending/)
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      assert_equal 0, code, out
      assert_equal 2, launches.size
    end
  end

  def test_attack_beside_evaluate_is_refused_when_evaluates_own_predecessor_is_incomplete
    with_parallel_record(complete: THROUGH_VERIFY - %w[verify]) do |dir, _record|
      before = tree_bytes(dir)
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_empty launches
      assert_includes out, "06-verification"
      assert_equal before, tree_bytes(dir)
    end
  end

  # --- environment ---------------------------------------------------------------

  def test_env_values_are_expanded_per_phase_and_reach_only_the_launch_environment
    with_parallel_record do |dir, _record|
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude",
                                         "--env", "DATABASE_URL=db_{phase}", "--env", "PLAIN=same")
      assert_equal 0, code, out
      by = launches.to_h { |l| [phase_of(l), l.env] }
      assert_equal "db_evaluate", by["evaluate"]["DATABASE_URL"]
      assert_equal "db_attack", by["attack"]["DATABASE_URL"]
      assert_equal "same", by["attack"]["PLAIN"]
      assert_equal "1", by["attack"]["SOFT_FOUNDRY_PARALLEL"]
    end
  end

  def test_a_parallel_run_without_env_warns_that_isolation_is_the_adopters
    with_parallel_record do |dir, _record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      assert_equal 0, code
      assert_match(/^warn: .*isolation .*adopter's responsibility/, out)
      _, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "A=1", "--dry-run")
      refute_match(/^warn: .*isolation/, out)
    end
  end

  def test_a_secret_value_appears_in_no_file_and_no_output
    secret = "s3cr3t-distinctive-value-7731"
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "API_TOKEN=#{secret}-{phase}") do |launch|
        raise "failed with #{launch.inspect}" if phase_of(launch) == "attack"

        0
      end
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      refute_includes out, secret
      assert_includes out, "API_TOKEN"
      Dir.glob("**/*", File::FNM_DOTMATCH, base: dir).select { |f| File.file?(File.join(dir, f)) && !f.start_with?(".git/") }.each do |f|
        refute_includes File.binread(File.join(dir, f)), secret, f
      end
      refute_includes record.metadata.to_s, secret
    end
  end

  def test_dry_run_prints_the_commands_and_variable_names_only_and_writes_nothing
    with_parallel_record do |dir, _record|
      before = tree_bytes(dir)
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "API_TOKEN=hunter2-{phase}", "--dry-run")
      assert_equal 0, code, out
      assert_empty launches
      refute_includes out, "hunter2"
      assert_equal 2, out.scan(/^would run (evaluate|attack) of c1 with:/).size
      assert_includes out, "API_TOKEN"
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_a_single_phase_run_also_takes_env_and_leaves_the_parallel_flag_unset
    with_parallel_record(complete: THROUGH_VERIFY + %w[evaluate]) do |dir, _record|
      code, out, launches = run_parallel(dir, "attack", "--shell", "claude", "--env", "DB=db_{phase}")
      assert_equal 0, code, out
      assert_equal "db_attack", launches.first.env["DB"]
      refute launches.first.env.key?("SOFT_FOUNDRY_PARALLEL")
    end
  end

  # --- commits and the record -------------------------------------------------------

  def test_sessions_are_told_the_start_head_and_not_to_commit_and_the_runner_commits_nothing
    with_parallel_record do |dir, _record|
      start = head(dir)
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      assert_equal 0, code, out
      assert(launches.all? { |l| l.prompt.include?("commit_sha is #{start}") && l.prompt.include?("do not commit") })
      assert_equal start, head(dir)
      refute_match(/^warn: .*HEAD/, out)
    end
  end

  def test_a_session_that_commits_triggers_a_warning_and_a_non_zero_exit
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        complete!(record, dir, phase_of(launch))
        commit_all(dir, "a session committed") if phase_of(launch) == "evaluate"
        0
      end
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out
      assert_match(/^warn: HEAD moved from [0-9a-f]{7} to [0-9a-f]{7} during the run/, out)
    end
  end

  def test_current_phase_afterwards_is_the_first_phase_not_complete
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        complete!(record, dir, phase_of(launch))
        0
      end
      assert_equal 0, code, out
      assert_equal "review", record.metadata["current_phase"]
    end
    with_parallel_record do |dir, record|
      run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") { |launch| phase_of(launch) == "attack" ? 1 : (complete!(record, dir, "evaluate"); 0) }
      assert_equal "attack", record.metadata["current_phase"]
    end
  end

  def test_each_handoff_records_how_its_phase_ran
    with_parallel_record do |dir, record|
      run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      %w[evaluate attack].each do |id|
        by = record.handoff(record.control_plane.phase(id))["executed_by"]
        assert_equal "soft-foundry phase run", by["runner"]
        assert_equal true, by["fresh_context"]
        assert_equal 0, by["exit_status"]
        refute_nil by["finished_at"]
      end
    end
  end

  def test_a_stale_complete_phase_is_reopened_once_in_lifecycle_order_then_run
    with_parallel_record(complete: THROUGH_VERIFY + %w[evaluate attack]) do |dir, record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed")
      code, out, launches = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude")
      assert_equal 0, code, out
      assert_equal 2, launches.size
      entries = record.metadata["phase_reopenings"]
      assert_equal 1, entries.size, "evaluate's reopen resets attack, so attack is not reopened again"
      assert_equal "auto", entries.first["source"]
      assert_equal "evaluate", entries.first["phase"]
      assert_includes out, "phase reopen: reopened evaluate (automatic: evidence stale at"
    end
  end

  # --- repeated simultaneous finishes ---------------------------------------------------

  def test_twenty_simultaneous_finishes_lose_no_update
    with_parallel_record do |dir, record|
      20.times do |n|
        gate = Queue.new
        code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
          gate << 1
          sleep 0.01 until gate.size >= 2
          complete!(record, dir, phase_of(launch))
          0
        end
        assert_equal 0, code, "run #{n}: #{out}"
        tree_bytes(dir).each { |f, bytes| YAML.safe_load(bytes, permitted_classes: [Time, Date]) if f.end_with?(".yml") }
        %w[evaluate attack].each do |id|
          h = record.handoff(record.control_plane.phase(id))
          assert_equal "complete", h["status"], "run #{n} #{id}"
          assert_equal 0, h.dig("executed_by", "exit_status"), "run #{n} #{id}"
        end
        assert_equal "review", record.metadata["current_phase"]
        sh(dir, "git", "checkout", "-q", "--", "changes")
        sh(dir, "git", "clean", "-fdq", "--", "changes")
      end
    end
  end

  # --- real processes ----------------------------------------------------------------------

  # A directory holding a stand-in `claude` that runs the given shell body.
  def with_stub_shell(body)
    Dir.mktmpdir("stub-bin") do |bin|
      path = File.join(bin, "claude")
      File.write(path, "#!/bin/sh\n#{body}\n")
      File.chmod(0o755, path)
      yield bin
    end
  end

  def spawn_cli(dir, bin, *args, env: {})
    full = { "PATH" => "#{bin}:#{ENV['PATH']}", "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil,
             "OPENROUTER_API_KEY" => nil, "SOFT_FOUNDRY_BILLING" => nil, "SOFT_FOUNDRY_PHASE" => nil, "SOFT_FOUNDRY_PARALLEL" => nil }.merge(env)
    rd, wr = IO.pipe
    pid = Process.spawn(full, "ruby", "-I", File.join(FoundryFixture::REPO_ROOT, "lib"), EXE, *args, chdir: dir, out: wr, err: wr)
    wr.close
    [pid, rd]
  end

  def test_two_two_second_sessions_take_under_three_seconds
    with_parallel_record do |dir, _record|
      with_stub_shell("sleep 2") do |bin|
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        pid, rd = spawn_cli(dir, bin, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude")
        output = rd.read
        Process.wait(pid)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        assert_operator elapsed, :<, 3.0 + 1.0, "includes ruby startup: #{output}"
        assert_operator elapsed, :>=, 2.0
        assert_includes output, "phase evaluate:"
      end
    end
  end

  def test_the_environment_reaches_the_child_and_no_secret_is_in_the_process_list
    secret = "ps-secret-value-4417"
    with_parallel_record do |dir, _record|
      Dir.mktmpdir("probe") do |probe|
        body = "printf '%s|%s|%s' \"$SOFT_FOUNDRY_PHASE\" \"$SOFT_FOUNDRY_PARALLEL\" \"$API_TOKEN\" > #{probe}/$SOFT_FOUNDRY_PHASE.env; sleep 1.5"
        with_stub_shell(body) do |bin|
          pid, rd = spawn_cli(dir, bin, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "API_TOKEN=#{secret}-{phase}")
          sleep 0.8
          listing = `ps -ww -A -o command=`
          output = rd.read
          Process.wait(pid)
          refute_includes listing, secret
          refute_includes output, secret
          assert_equal "evaluate|1|#{secret}-evaluate", File.read(File.join(probe, "evaluate.env"))
          assert_equal "attack|1|#{secret}-attack", File.read(File.join(probe, "attack.env"))
        end
      end
    end
  end

  def test_interrupting_the_run_signals_every_child
    with_parallel_record do |dir, _record|
      Dir.mktmpdir("probe") do |probe|
        body = "echo $$ > #{probe}/$SOFT_FOUNDRY_PHASE.pid; trap 'touch #{probe}/$SOFT_FOUNDRY_PHASE.term; exit 143' TERM INT; sleep 30 & wait"
        with_stub_shell(body) do |bin|
          pid, rd = spawn_cli(dir, bin, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude")
          deadline = Time.now + 10
          sleep 0.1 until %w[evaluate attack].all? { |id| File.exist?(File.join(probe, "#{id}.pid")) } || Time.now > deadline
          Process.kill("INT", pid)
          waiter = Thread.new { Process.wait2(pid) }
          assert waiter.join(10), "the run did not end after the interrupt"
          status = waiter.value[1]
          output = rd.read
          refute_equal 0, status.exitstatus.to_i
          %w[evaluate attack].each do |id|
            assert File.exist?(File.join(probe, "#{id}.term")), "#{id} child did not receive the signal: #{output}"
            child = File.read(File.join(probe, "#{id}.pid")).to_i
            assert_raises(Errno::ESRCH, "#{id} child still running") { Process.kill(0, child) }
          end
          assert_includes output, "phase evaluate: fail"
        end
      end
    end
  end
end
