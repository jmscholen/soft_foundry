# frozen_string_literal: true

require_relative "test_helper"
require "json"

# The session ledger: `soft-foundry session log` as a prompt hook that
# records every Claude Code, Codex, and Grok session, and `sessions` /
# `resume` to find one again from any folder.
class SessionLedgerTest < Minitest::Test
  include FoundryFixture

  def with_ledger
    Dir.mktmpdir("sf-ledger") do |dir|
      yield File.join(dir, "state", "sessions.jsonl"), dir
    end
  end

  def ledger(path, now: Time.utc(2026, 10, 7, 12, 0, 0)) = SoftFoundry::SessionLedger.new(path, now: -> { now })

  def claude_prompt(id, cwd, prompt, transcript: nil)
    { "session_id" => id, "cwd" => cwd, "prompt" => prompt, "hook_event_name" => "UserPromptSubmit", "transcript_path" => transcript }.compact
  end

  def grok_prompt(id, cwd, prompt)
    { "hookEventName" => "user_prompt_submit", "hook_event_name" => "UserPromptSubmit", "sessionId" => id, "session_id" => id, "cwd" => cwd, "prompt" => prompt }
  end

  def log_cli(path, payload, shell: "claude", root: Dir.pwd)
    out = StringIO.new
    err = StringIO.new
    input = StringIO.new(payload.is_a?(String) ? payload : JSON.generate(payload))
    code = nil
    with_env("SOFT_FOUNDRY_SESSIONS" => path) do
      code = SoftFoundry::CLI.new(["session", "log", "--shell", shell], out: out, err: err, input: input, root: root).run
    end
    [code, out.string, err.string]
  end

  def ledger_cli(path, *args, root: Dir.pwd)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env("SOFT_FOUNDRY_SESSIONS" => path) do
      code = SoftFoundry::CLI.new(args, out: out, err: err, root: root).run
    end
    [code, out.string, err.string]
  end

  # --- capture ---------------------------------------------------------------

  def test_one_entry_per_session_updated_in_place
    with_ledger do |path, dir|
      l = ledger(path)
      l.record(claude_prompt("aaa-1", dir, "first thing"), shell: "claude")
      ledger(path, now: Time.utc(2026, 10, 7, 13, 0, 0)).record(claude_prompt("aaa-1", dir, "second thing"), shell: "claude")
      l.record(claude_prompt("bbb-2", dir, "other session"), shell: "claude")
      entries = ledger(path).entries
      assert_equal 2, entries.size
      first = entries.find { |e| e["session_id"] == "aaa-1" }
      assert_equal "first thing", first["first_prompt"]
      assert_equal "second thing", first["latest_prompt"]
      assert_equal "2026-10-07T12:00:00Z", first["first_at"]
      assert_equal "2026-10-07T13:00:00Z", first["last_at"]
      assert_equal "claude", first["agent"]
      assert_equal File.realpath(dir), File.realpath(first["cwd"])
    end
  end

  def test_records_repository_branch_change_and_phase_from_the_folder
    with_fixture_repo do |repo|
      sh(repo, "git", "checkout", "-qb", "change/c1")
      cli(repo, "change", "new", "c1")
      meta = File.join(repo, "changes", "c1", "metadata.yml")
      File.write(meta, File.read(meta).sub(/^current_phase: intake.*$/, "current_phase: verify"))
      FileUtils.mkdir_p(File.join(repo, "lib", "deep"))
      with_ledger do |path, dir|
        entry = ledger(path).record(claude_prompt("s-1", File.join(repo, "lib", "deep"), "hi", transcript: "/tmp/t.jsonl"), shell: "claude")
        assert_equal File.realpath(repo), entry["repo"]
        assert_equal "change/c1", entry["branch"]
        assert_equal "c1", entry["change"]
        assert_equal "verify", entry["phase"]
        assert_equal "/tmp/t.jsonl", entry["transcript"]

        outside = ledger(path).record(claude_prompt("s-2", dir, "no repo here"), shell: "codex")
        assert_nil outside["repo"]
        assert_nil outside["branch"]
        assert_nil outside["change"]
        assert_equal "codex", outside["agent"]
      end
    end
  end

  def test_prompts_are_masked_flattened_and_cut_and_the_files_are_private
    with_ledger do |path, dir|
      key = "sk-ant-api03-" + ("A" * 40)
      long = "line one\n\n  line two #{key} " + ("x" * 300)
      entry = ledger(path).record(claude_prompt("s-1", dir, long), shell: "claude")
      refute_includes entry["first_prompt"], key
      refute_includes entry["first_prompt"], "\n"
      assert_operator entry["first_prompt"].length, :<=, 141
      assert entry["first_prompt"].end_with?("…")
      assert_includes entry["first_prompt"], "line one line two"
      refute_includes File.read(path), key
      assert_equal 0o700, File.stat(File.dirname(path)).mode & 0o777
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
  end

  def test_control_characters_are_removed_from_recorded_text
    with_ledger do |path, dir|
      entry = ledger(path).record(claude_prompt("s-1", dir, "red \e[31mtext\e[0m bell\a end"), shell: "claude")
      refute_match(/[\x00-\x1f\x7f]/, entry["first_prompt"])
      assert_includes entry["first_prompt"], "text"
    end
  end

  def test_grok_payloads_are_recorded_as_grok_whatever_the_shell_flag_says
    with_ledger do |path, dir|
      entry = ledger(path).record(grok_prompt("0199-abc", dir, "hello"), shell: "claude")
      assert_equal "grok", entry["agent"]
      assert_includes SoftFoundry::SessionLedger.resume_command(entry), "grok --resume 0199-abc"
    end
  end

  def test_a_session_id_that_is_not_a_plain_identifier_is_never_recorded
    with_ledger do |path, dir|
      ["abc; rm -rf ~", "abc\nxyz", "$(id)", "", "a" * 129].each do |bad|
        assert_nil ledger(path).record(claude_prompt(bad, dir, "p"), shell: "claude"), bad.inspect
      end
      assert_empty ledger(path).entries
    end
  end

  def test_resume_commands_quote_the_folder_and_use_each_agents_form
    with_ledger do |path, dir|
      odd = File.join(dir, "it's a $(dir) here")
      FileUtils.mkdir_p(odd)
      l = ledger(path)
      c = l.record(claude_prompt("c-1", odd, "p"), shell: "claude")
      x = l.record(claude_prompt("x-1", odd, "p"), shell: "codex")
      g = l.record(grok_prompt("g-1", odd, "p"), shell: "grok")
      cmd = SoftFoundry::SessionLedger.resume_command(c)
      assert cmd.end_with?(" && claude --resume c-1"), cmd
      assert_includes SoftFoundry::SessionLedger.resume_command(x), " && codex resume x-1"
      assert_includes SoftFoundry::SessionLedger.resume_command(g), " && grok --resume g-1"
      # The quoted folder is exactly the folder when a shell reads it back.
      out, status = Open3.capture2("sh", "-c", "#{cmd.split(' && ').first} && pwd -P")
      assert status.success?
      assert_equal File.realpath(odd), out.strip
    end
  end

  def test_status_word_says_whether_a_session_can_be_resumed
    with_ledger do |path, dir|
      gone = File.join(dir, "gone")
      FileUtils.mkdir_p(gone)
      transcript = File.join(dir, "t.jsonl")
      File.write(transcript, "{}\n")
      l = ledger(path)
      ok = l.record(claude_prompt("ok-1", dir, "p", transcript: transcript), shell: "claude")
      no_t = l.record(claude_prompt("nt-1", dir, "p", transcript: File.join(dir, "missing.jsonl")), shell: "claude")
      no_f = l.record(claude_prompt("nf-1", gone, "p"), shell: "claude")
      FileUtils.rm_rf(gone)
      assert_equal "resumable", SoftFoundry::SessionLedger.status(ok)
      assert_equal "transcript missing", SoftFoundry::SessionLedger.status(no_t)
      assert_equal "folder missing", SoftFoundry::SessionLedger.status(no_f)
    end
  end

  def test_concurrent_writers_lose_no_entries
    with_ledger do |path, dir|
      pids = 20.times.map do |i|
        fork do
          ledger(path).record(claude_prompt("p-#{i}", dir, "prompt #{i}"), shell: "claude")
          exit!(0)
        end
      end
      pids.each { |pid| Process.wait(pid) }
      assert_equal 20, ledger(path).entries.size
    end
  end

  def test_a_corrupt_line_is_kept_and_does_not_stop_recording
    with_ledger do |path, dir|
      ledger(path).record(claude_prompt("a-1", dir, "p"), shell: "claude")
      File.open(path, "a") { |f| f.puts "{not json" }
      ledger(path).record(claude_prompt("b-1", dir, "p"), shell: "claude")
      assert_includes File.read(path), "{not json"
      assert_equal %w[a-1 b-1], ledger(path).entries.map { |e| e["session_id"] }.sort
    end
  end

  def test_a_symlink_at_the_ledger_path_is_refused
    with_ledger do |path, dir|
      FileUtils.mkdir_p(File.dirname(path))
      target = File.join(dir, "elsewhere")
      File.write(target, "")
      File.symlink(target, path)
      assert_raises(SoftFoundry::TargetError) { ledger(path).record(claude_prompt("a-1", dir, "p"), shell: "claude") }
      assert_equal "", File.read(target)
    end
  end

  # --- the hook command --------------------------------------------------------

  def test_session_log_is_silent_and_exits_zero_whatever_it_is_given
    with_ledger do |path, dir|
      ["", "{not json", "[]", JSON.generate({ "cwd" => dir }), JSON.generate(claude_prompt("ok-1", dir, "fine"))].each do |payload|
        code, out, err = log_cli(path, payload)
        assert_equal 0, code, payload
        assert_empty out, payload
        assert_empty err, payload
      end
      assert_equal ["ok-1"], ledger(path).entries.map { |e| e["session_id"] }
      # An unwritable location: a file where the directory should be.
      blocked = File.join(dir, "blocked")
      File.write(blocked, "")
      code, out, err = log_cli(File.join(blocked, "sessions.jsonl"), claude_prompt("x-1", dir, "p"))
      assert_equal [0, "", ""], [code, out, err]
    end
  end

  def test_session_log_records_fast_with_a_large_ledger
    with_ledger do |path, dir|
      l = ledger(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") do |f|
        5000.times { |i| f.puts JSON.generate({ "agent" => "claude", "session_id" => "old-#{i}", "cwd" => dir, "first_prompt" => "p" * 140, "latest_prompt" => "p" * 140, "first_at" => "2026-01-01T00:00:00Z", "last_at" => "2026-01-01T00:00:00Z" }) }
      end
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      code, = log_cli(path, claude_prompt("new-1", dir, "fresh"))
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      assert_equal 0, code
      assert_operator elapsed, :<, 1.0
      assert_equal 5001, l.entries.size
    end
  end

  # --- lookup ------------------------------------------------------------------

  def seed(path, dir)
    t = ->(h) { Time.utc(2026, 10, 7, h, 0, 0) }
    gone = File.join(dir, "gone")
    FileUtils.mkdir_p(gone)
    rows = [
      ["c-old", "claude", "implement the ledger", "c1", "implement", 9, dir],
      ["x-new", "codex", "review the ledger code", "c1", "review", 11, dir],
      ["g-mid", "grok", "write the QR generator", "c2", "plan", 10, dir],
      ["c-gone", "claude", "ledger work in a deleted folder", "c3", "verify", 8, gone]
    ]
    rows.each do |id, agent, prompt, change, phase, hour, cwd|
      payload = agent == "grok" ? grok_prompt(id, cwd, prompt) : claude_prompt(id, cwd, prompt)
      ledger(path, now: t.call(hour)).record(payload, shell: agent)
    end
    # Change and phase come from the folder in real use; set them directly here.
    lines = File.readlines(path).map { |l| JSON.parse(l) }
    rows.each { |id, _, _, change, phase| e = lines.find { |x| x["session_id"] == id }; e["change"] = change; e["phase"] = phase }
    File.write(path, lines.map { |e| JSON.generate(e) }.join("\n") + "\n")
    FileUtils.rm_rf(gone)
  end

  def test_sessions_matches_every_word_and_filter_newest_first
    with_ledger do |path, dir|
      seed(path, dir)
      code, out, = ledger_cli(path, "sessions", "ledger")
      assert_equal 0, code
      ids = out.scan(/resume: .* (\S+)$/).flatten
      assert_equal %w[x-new c-old c-gone], ids
      assert_includes out, "sessions: 3 recorded sessions match"
      assert_match(/^session: .* codex resumable$/, out)
      assert_match(/^session: .* claude folder missing$/, out)

      _, out, = ledger_cli(path, "sessions", "LEDGER", "review")
      assert_equal ["x-new"], out.scan(/resume: .* (\S+)$/).flatten
      _, out, = ledger_cli(path, "sessions", "--change", "c2")
      assert_equal ["g-mid"], out.scan(/resume: .* (\S+)$/).flatten
      _, out, = ledger_cli(path, "sessions", "--agent", "claude", "--phase", "implement")
      assert_equal ["c-old"], out.scan(/resume: .* (\S+)$/).flatten
      _, out, = ledger_cli(path, "sessions", "--limit", "1")
      assert_equal ["x-new"], out.scan(/resume: .* (\S+)$/).flatten

      _, out, = ledger_cli(path, "sessions", "ledger", "--json")
      data = JSON.parse(out)
      assert_equal %w[x-new c-old c-gone], data.map { |e| e["session_id"] }
      assert_equal "folder missing", data.last["status"]
      assert data.first["resume"].end_with?("codex resume x-new")
    end
  end

  def test_sessions_with_no_ledger_says_how_to_start_one
    with_ledger do |path, _dir|
      code, out, = ledger_cli(path, "sessions")
      assert_equal 0, code
      assert_includes out, "sessions: none found"
      assert_includes out, "soft-foundry hooks install --sessions"
    end
  end

  def test_resume_prints_the_newest_command_for_a_change_and_fails_when_there_is_none
    with_ledger do |path, dir|
      seed(path, dir)
      code, out, = ledger_cli(path, "resume", "c1")
      assert_equal 0, code
      assert out.strip.end_with?("codex resume x-new"), out
      _, out, = ledger_cli(path, "resume", "c1", "implement")
      assert out.strip.end_with?("claude --resume c-old"), out
      _, out, = ledger_cli(path, "resume", "c1", "--agent", "claude")
      assert out.strip.end_with?("claude --resume c-old"), out
      code, out, err = ledger_cli(path, "resume", "nope")
      assert_equal 1, code
      assert_empty out
      assert_includes err, "no recorded session for change nope"
    end
  end
end
