# frozen_string_literal: true

require_relative "test_helper"
require "json"

# REV-SEC-001: a session ID read back from the ledger is trusted only if
# it is one `record` would have written, and it is quoted anyway when a
# resume command is built.
class SessionIdQuotingTest < Minitest::Test
  include FoundryFixture

  PLANTED = ["x; touch PWNED", "$(id)", "a`id`", "ok\nmore"].freeze

  def with_planted_ledger
    Dir.mktmpdir("sf-state") do |dir|
      path = File.join(dir, "state", "sessions.jsonl")
      SoftFoundry::SessionLedger.new(path).record({ "session_id" => "good-1", "cwd" => dir, "prompt" => "planted test" }, shell: "claude")
      File.open(path, "a") do |f|
        PLANTED.each { |id| f.puts JSON.generate({ "agent" => "claude", "session_id" => id, "cwd" => dir, "change" => "c1", "first_prompt" => "planted test", "last_at" => "2099-01-01T00:00:00Z" }) }
        f.puts JSON.generate({ "agent" => "sh -c id;", "session_id" => "agent-1", "cwd" => dir, "change" => "c1", "first_prompt" => "planted test", "last_at" => "2099-01-01T00:00:00Z" })
      end
      yield path, dir
    end
  end

  def run_cli(path, *args)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env("SOFT_FOUNDRY_SESSIONS" => path) { code = SoftFoundry::CLI.new(args, out: out, err: err, root: Dir.pwd).run }
    [code, out.string, err.string]
  end

  def test_lookup_skips_lines_record_would_never_have_written
    with_planted_ledger do |path, _dir|
      ids = SoftFoundry::SessionLedger.new(path).search(words: ["planted"]).map { |e| e["session_id"] }
      assert_equal ["good-1"], ids
      _, out, = run_cli(path, "sessions", "planted")
      assert_includes out, "sessions: 1 recorded session matches"
      PLANTED.each { |id| refute_includes out, id }
      refute_includes out, "agent-1"
      _, json, = run_cli(path, "sessions", "planted", "--json")
      assert_equal ["good-1"], JSON.parse(json).map { |e| e["session_id"] }
      code, out, = run_cli(path, "resume", "c1")
      assert_equal 1, code
      assert_empty out
      # The planted lines stay in the file; lookup just does not trust them.
      assert_equal PLANTED.size + 2, File.readlines(path).size
    end
  end

  def test_resume_command_quotes_the_session_id_too
    cmd = SoftFoundry::SessionLedger.resume_command({ "agent" => "claude", "session_id" => "x; touch PWNED", "cwd" => "/tmp" })
    assert cmd.end_with?("claude --resume x\;\\ touch\\ PWNED"), cmd
    plain = SoftFoundry::SessionLedger.resume_command({ "agent" => "grok", "session_id" => "0199-abc", "cwd" => "/tmp" })
    assert_equal "cd /tmp && grok --resume 0199-abc", plain
  end
end
