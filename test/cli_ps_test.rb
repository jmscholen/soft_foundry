# frozen_string_literal: true

require "json"
require_relative "test_helper"

class CLIPsTest < Minitest::Test
  include FoundryFixture

  SNAPSHOT = {
    "version" => 1, "generated_at" => "2026-10-02T05:00:00Z",
    "processes" => [
      { "pid" => 200, "command" => "phase run", "phase" => "verify", "change" => "pdf-review", "shell" => "claude", "port" => nil,
        "session" => { "pid" => 201, "name" => "claude" }, "repository" => "~/dev/other", "here" => false, "self" => false, "started_at" => "2026-10-02T04:02:33Z" },
      { "pid" => 100, "command" => "ui", "phase" => nil, "change" => nil, "shell" => nil, "port" => 4877,
        "session" => nil, "repository" => ".", "here" => true, "self" => false, "started_at" => "2026-10-02T04:36:11Z" },
      { "pid" => 999, "command" => "ps", "phase" => nil, "change" => nil, "shell" => nil, "port" => nil,
        "session" => nil, "repository" => ".", "here" => true, "self" => true, "started_at" => "2026-10-02T05:00:00Z" }
    ],
    "sessions" => [
      { "pid" => 900, "shell" => "claude", "terminal" => "ttys004", "repository" => ".", "here" => true, "branch" => "change/c1",
        "change" => "c1", "phase" => "implement", "status" => "in_progress", "started_at" => "2026-10-02T06:00:00Z" },
      { "pid" => 902, "shell" => "grok", "terminal" => nil, "repository" => "~/dev/other", "here" => false, "branch" => "main",
        "change" => nil, "phase" => nil, "status" => nil, "started_at" => "2026-10-02T06:02:00Z" }
    ],
    "recorded_runs" => [
      { "change" => "c1", "phase" => "specify", "shell" => "codex", "started_at" => "2026-10-02T04:00:00Z", "live" => false, "pid" => nil },
      { "change" => "c1", "phase" => "discover", "shell" => "codex", "started_at" => "2026-10-02T04:00:00Z", "live" => true, "pid" => 800 }
    ]
  }.freeze

  Fake = Struct.new(:data) do
    def snapshot = data
  end

  def ps(dir, *args, data: SNAPSHOT)
    out = StringIO.new
    err = StringIO.new
    code = SoftFoundry::CLI.new(["ps", *args], out: out, err: err, root: dir, processes: ->(_root) { Fake.new(data) }).run
    [code, out.string + err.string]
  end

  def test_ps_lists_each_process_on_a_line_and_leaves_itself_out
    with_fixture_repo do |dir|
      code, out = ps(dir)
      assert_equal 0, code, out
      lines = out.lines(chomp: true)
      assert_equal "running: 2 soft-foundry processes", lines[0]
      assert_equal "  pid 200  phase run verify  change pdf-review  shell claude (session pid 201)  in ~/dev/other  since 2026-10-02T04:02:33Z", lines[1]
      assert_equal "  pid 100  ui  port 4877  in this repository  since 2026-10-02T04:36:11Z", lines[2]
      assert_equal "sessions: 2 coding shells open in Soft Foundry repositories", lines[3]
      assert_equal "  pid 900  claude  terminal ttys004  change c1 (phase implement, in_progress)  branch change/c1  in this repository  since 2026-10-02T06:00:00Z", lines[4]
      assert_equal "  pid 902  grok  no change record for its branch  branch main  in ~/dev/other  since 2026-10-02T06:02:00Z", lines[5]
      assert_equal "recorded as started by phase run with no process found: 1", lines[6]
      assert_equal "  ! warn change c1 phase specify: started 2026-10-02T04:00:00Z (codex) and never finished; the session may have been interrupted", lines[7]
      assert_equal 8, lines.size
    end
  end

  def test_ps_with_nothing_running
    with_fixture_repo do |dir|
      code, out = ps(dir, data: SNAPSHOT.merge("processes" => [SNAPSHOT["processes"].last], "sessions" => [], "recorded_runs" => []))
      assert_equal 0, code
      assert_equal "running: no soft-foundry processes\nsessions: no coding shells open in Soft Foundry repositories\n", out
    end
  end

  def test_ps_reports_when_processes_cannot_be_listed
    with_fixture_repo do |dir|
      code, out = ps(dir, data: SNAPSHOT.merge("processes" => [], "recorded_runs" => [], "error" => "could not list processes: ps"))
      assert_equal 1, code
      assert_includes out, "could not list processes: ps"
    end
  end

  def test_ps_json_is_the_snapshot
    with_fixture_repo do |dir|
      code, out = ps(dir, "--json")
      assert_equal 0, code
      assert_equal JSON.parse(JSON.generate(SNAPSHOT)), JSON.parse(out)
    end
  end

  def test_ps_refuses_unknown_options_and_is_in_help
    with_fixture_repo do |dir|
      code, out = ps(dir, "--all")
      assert_equal 1, code
      assert_includes out, "unknown option(s): --all"
      _, help = cli(dir)
      assert_includes help, "soft-foundry ps [--json]"
    end
  end
end
