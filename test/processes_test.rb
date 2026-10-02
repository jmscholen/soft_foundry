# frozen_string_literal: true

require "json"
require_relative "test_helper"

class ProcessesTest < Minitest::Test
  include FoundryFixture

  HOME = Dir.home

  # What `ps` prints: pid, parent pid, start time, command line.
  PS = <<~TEXT
    100     1 Fri Oct  2 00:36:11 2026     /opt/ruby/bin/ruby -Ilib exe/soft-foundry ui --port 4877
    200     1 Fri Oct  2 00:02:33 2026     /opt/ruby/bin/ruby /opt/ruby/bin/soft-foundry phase run verify --change pdf-review --shell claude -- --dangerously-skip-permissions --api-key sk-secret
    201   200 Fri Oct  2 00:02:34 2026     /usr/local/bin/claude -p --dangerously-skip-permissions You are a fresh-context agent. Do not run soft-foundry phase run yourself.
    300     1 Fri Oct  2 01:00:00 2026     /opt/ruby/bin/soft-foundry ci
    400     1 Fri Oct  2 01:00:00 2026     vim soft-foundry.md
    401     1 Fri Oct  2 01:00:00 2026     grep soft-foundry phase run
    500     1 Fri Oct  2 01:00:00 2026     /tmp/soft-foundry phase run <script>alert(1)</script> --change ../../etc --shell <b>sh</b>
    600     1 Fri Oct  2 01:00:00 2026     ruby -w -I lib /work/exe/soft-foundry gate review --change team/alpha
  TEXT

  def processes(root, ps: PS, cwd: {})
    SoftFoundry::Processes.new(root, ps: -> { ps }, cwd: ->(pid) { cwd[pid] })
  end

  def by_pid(list) = list.to_h { |p| [p["pid"], p] }

  def test_lists_only_soft_foundry_processes_with_what_they_are_doing
    with_fixture_repo do |dir|
      list = by_pid(processes(dir).list)
      assert_equal [100, 200, 300, 500, 600], list.keys.sort

      assert_equal "ui", list[100]["command"]
      assert_equal 4877, list[100]["port"]

      run = list[200]
      assert_equal "phase run", run["command"]
      assert_equal "verify", run["phase"]
      assert_equal "pdf-review", run["change"]
      assert_equal "claude", run["shell"]
      assert_equal({ "pid" => 201, "name" => "claude" }, run["session"])
      assert_match(/\A2026-10-0\dT\d\d:\d\d:33Z\z/, run["started_at"])

      assert_equal "ci", list[300]["command"]
      assert_nil list[300]["session"]

      gate = list[600]
      assert_equal "gate", gate["command"]
      assert_equal "review", gate["phase"]
      assert_equal "team/alpha", gate["change"]
    end
  end

  # A command line is whatever a process chose to call itself, and a
  # session's prompt and a runner's passthrough flags are not ours to
  # repeat. Only named, validated fields leave.
  def test_nothing_from_a_command_line_is_repeated_beyond_validated_fields
    with_fixture_repo do |dir|
      snapshot = processes(dir).snapshot
      text = JSON.generate(snapshot)
      refute_includes text, "sk-secret"
      refute_includes text, "dangerously"
      refute_includes text, "fresh-context"
      refute_includes text, "script"
      refute_includes text, "<b>"
      refute_includes text, "../"

      spoof = by_pid(snapshot["processes"])[500]
      assert_equal "phase run", spoof["command"]
      assert_nil spoof["phase"]
      assert_nil spoof["change"]
      assert_equal "claude", spoof["shell"], "an unknown shell name is not repeated; the default is"
      assert_equal snapshot, JSON.parse(text)
    end
  end

  def test_says_which_repository_each_process_is_in
    with_fixture_repo do |dir|
      real = File.realpath(dir)
      list = by_pid(processes(dir, cwd: { 100 => real, 200 => File.join(HOME, "dev", "other"), 300 => nil }).list)
      assert list[100]["here"]
      assert_equal ".", list[100]["repository"]
      refute list[200]["here"]
      assert_equal "~/dev/other", list[200]["repository"]
      refute list[300]["here"]
      assert_nil list[300]["repository"]
    end
  end

  def test_change_comes_from_the_branch_when_the_command_does_not_name_it
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1", "--title", "x")
      ps = "700 1 Fri Oct  2 01:00:00 2026 ruby /bin/soft-foundry phase run intake\n701 1 Fri Oct  2 01:00:00 2026 ruby /bin/soft-foundry ui\n"
      list = by_pid(processes(dir, ps: ps, cwd: { 700 => File.realpath(dir), 701 => File.realpath(dir) }).list)
      assert_equal "c1", list[700]["change"]
      assert_nil list[701]["change"], "a command that is not about one change has none"
    end
  end

  # `phase run` stamps the handoff when it starts and again when the
  # session returns. A start with no finish and no live process is a run
  # that was interrupted.
  def test_recorded_runs_are_matched_with_live_processes
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1", "--title", "x")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
      stamp = lambda do |phase, finished|
        path = record.handoff_path(plane.phase(phase))
        h = YAML.safe_load_file(path)
        h["status"] = "in_progress"
        h["executed_by"] = { "runner" => "soft-foundry phase run", "shell" => "codex", "fresh_context" => true,
                             "started_at" => "2026-10-02T04:00:00Z", "finished_at" => finished, "exit_status" => finished ? 0 : nil }
        File.write(path, YAML.dump(h))
      end
      stamp.call("intake", "2026-10-02T04:05:00Z")
      stamp.call("discover", nil)
      stamp.call("specify", nil)

      ps = "800 1 Fri Oct  2 00:00:00 2026 ruby /bin/soft-foundry phase run discover --change c1 --shell codex\n"
      runs = processes(dir, ps: ps, cwd: { 800 => File.realpath(dir) }).snapshot["recorded_runs"]
      assert_equal %w[discover specify], runs.map { |r| r["phase"] }
      assert_equal [true, false], runs.map { |r| r["live"] }
      assert_equal({ "change" => "c1", "phase" => "specify", "shell" => "codex", "started_at" => "2026-10-02T04:00:00Z", "live" => false, "pid" => nil }, runs.last)
      assert_equal 800, runs.first["pid"]
    end
  end

  def test_an_unreadable_ps_or_record_does_not_raise
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "broken", "--title", "x")
      File.write(File.join(dir, "changes", "broken", "metadata.yml"), "change: [unterminated\n")
      snapshot = SoftFoundry::Processes.new(dir, ps: -> { raise Errno::ENOENT, "ps" }, cwd: ->(_) {}).snapshot
      assert_equal [], snapshot["processes"]
      assert_equal [], snapshot["recorded_runs"]
      assert_includes snapshot["error"], "could not list processes"
      assert_equal [], processes(dir, ps: "garbage line\n\n  12 x\n").list
    end
  end

  # The real thing: a server started here is found by its pid, with its
  # repository, through the real `ps`.
  def test_finds_a_real_running_process
    with_fixture_repo do |dir|
      exe = File.join(REPO_ROOT, "exe", "soft-foundry")
      pid = Process.spawn(RbConfig.ruby, "-I#{File.join(REPO_ROOT, 'lib')}", exe, "ui", "--port", "0", chdir: dir, out: File::NULL, err: File::NULL)
      begin
        found = nil
        40.times do
          found = SoftFoundry::Processes.new(dir).list.find { |p| p["pid"] == pid }
          break if found
          sleep 0.1
        end
        assert found, "the spawned server is listed"
        assert_equal "ui", found["command"]
        assert found["here"]
        assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, found["started_at"])
        refute found["self"]
      ensure
        Process.kill("TERM", pid)
        Process.wait(pid)
      end
    end
  end
end
