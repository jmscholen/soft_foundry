# frozen_string_literal: true

require_relative "test_helper"
require "json"

# `soft-foundry hooks install --sessions`: the session hook at user level
# for Claude Code, Codex, and Grok, the find-session skill, uninstall, and
# what doctor says. Always against a temporary home directory.
class SessionHooksTest < Minitest::Test
  include FoundryFixture

  def with_home
    Dir.mktmpdir("sf-home") { |home| yield home }
  end

  def hooks_cli(home, *args, root: Dir.pwd)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env("HOME" => home) do
      code = SoftFoundry::CLI.new(["hooks", *args], out: out, err: err, root: root).run
    end
    [code, out.string + err.string]
  end

  def json(path) = JSON.parse(File.read(path))

  def session_entries(path)
    Array(json(path).dig("hooks", "UserPromptSubmit")).select do |e|
      Array(e["hooks"]).any? { |h| h["command"].to_s.include?("soft-foundry:sessions") }
    end
  end

  def test_install_writes_one_entry_per_agent_keeps_other_settings_and_is_idempotent
    with_home do |home|
      claude = File.join(home, ".claude", "settings.json")
      codex = File.join(home, ".codex", "hooks.json")
      FileUtils.mkdir_p(File.dirname(claude))
      FileUtils.mkdir_p(File.dirname(codex))
      File.write(claude, JSON.generate({ "theme" => "dark", "hooks" => { "UserPromptSubmit" => [{ "hooks" => [{ "type" => "command", "command" => "echo mine" }] }], "PreToolUse" => [{ "matcher" => "Bash", "hooks" => [{ "type" => "command", "command" => "echo pre" }] }] } }))
      File.write(codex, JSON.generate({ "description" => "mine", "hooks" => {} }))

      2.times do
        code, out = hooks_cli(home, "install", "--sessions")
        assert_equal 0, code, out
      end
      grok = File.join(home, ".grok", "hooks", "soft-foundry-sessions.json")
      [claude, codex, grok].each { |p| assert_equal 1, session_entries(p).size, p }
      assert_includes session_entries(claude).first.to_s, "--shell claude"
      assert_includes session_entries(codex).first.to_s, "--shell codex"
      assert_includes session_entries(grok).first.to_s, "--shell grok"

      data = json(claude)
      assert_equal "dark", data["theme"]
      assert(data["hooks"]["UserPromptSubmit"].any? { |e| e.to_s.include?("echo mine") })
      assert_equal "echo pre", data["hooks"]["PreToolUse"].first["hooks"].first["command"]
      assert_equal "mine", json(codex)["description"]

      %w[.claude/skills/find-session/SKILL.md .agents/skills/find-session/SKILL.md].each do |rel|
        skill = File.read(File.join(home, rel))
        assert_includes skill, "name: find-session"
        assert_includes skill, "soft-foundry sessions"
      end
    end
  end

  def test_install_says_what_it_did_and_how_codex_trust_works
    with_home do |home|
      _, out = hooks_cli(home, "install", "--sessions")
      assert_match(/^installed session hook in .*\.claude\/settings\.json/, out)
      assert_match(/^installed session hook in .*\.codex\/hooks\.json/, out)
      assert_match(/^installed session hook in .*\.grok\/hooks\/soft-foundry-sessions\.json/, out)
      assert_includes out, "/hooks"
      assert_includes out, "ledger:"
    end
  end

  def test_the_hook_command_fails_open_and_prints_nothing
    with_home do |home|
      hooks_cli(home, "install", "--sessions")
      command = session_entries(File.join(home, ".claude", "settings.json")).first["hooks"].first["command"]
      out, err, status = Open3.capture3({ "PATH" => "/usr/bin:/bin", "HOME" => home }, "sh", "-c", command, stdin_data: "{}")
      assert status.success?
      assert_empty out
      assert_empty err
    end
  end

  def test_uninstall_removes_only_soft_foundry_entries_and_skills
    with_home do |home|
      claude = File.join(home, ".claude", "settings.json")
      FileUtils.mkdir_p(File.dirname(claude))
      File.write(claude, JSON.generate({ "hooks" => { "UserPromptSubmit" => [{ "hooks" => [{ "type" => "command", "command" => "echo mine" }] }] } }))
      hooks_cli(home, "install", "--sessions")
      code, out = hooks_cli(home, "uninstall", "--sessions")
      assert_equal 0, code
      assert_match(/^removed session hook from .*settings\.json/, out)
      assert_empty session_entries(claude)
      assert(json(claude)["hooks"]["UserPromptSubmit"].any? { |e| e.to_s.include?("echo mine") })
      refute File.exist?(File.join(home, ".claude", "skills", "find-session", "SKILL.md"))
      refute File.exist?(File.join(home, ".grok", "hooks", "soft-foundry-sessions.json"))
    end
  end

  def test_a_find_session_skill_someone_else_wrote_is_left_alone
    with_home do |home|
      mine = File.join(home, ".claude", "skills", "find-session", "SKILL.md")
      FileUtils.mkdir_p(File.dirname(mine))
      File.write(mine, "my own skill\n")
      _, out = hooks_cli(home, "install", "--sessions")
      assert_equal "my own skill\n", File.read(mine)
      assert_match(/^skip .*find-session.*not written by soft-foundry/, out)
      hooks_cli(home, "uninstall", "--sessions")
      assert_equal "my own skill\n", File.read(mine)
    end
  end

  def test_a_symlinked_settings_file_is_refused
    with_home do |home|
      FileUtils.mkdir_p(File.join(home, ".claude"))
      target = File.join(home, "real.json")
      File.write(target, "{}")
      File.symlink(target, File.join(home, ".claude", "settings.json"))
      code, out = hooks_cli(home, "install", "--sessions")
      refute_equal 0, code
      assert_includes out, "symlink"
      assert_equal "{}", File.read(target)
    end
  end

  def test_doctor_reports_the_session_hook
    with_fixture_repo do |dir|
      with_home do |home|
        out = StringIO.new
        with_env("HOME" => home) { SoftFoundry::CLI.new(["doctor"], out: out, err: out, root: dir).run }
        assert_match(/session hook.*not installed.*hooks install --sessions/, out.string)
        hooks_cli(home, "install", "--sessions")
        out = StringIO.new
        with_env("HOME" => home) { SoftFoundry::CLI.new(["doctor"], out: out, err: out, root: dir).run }
        assert_match(/session hook.*installed for claude, codex, grok/, out.string)
      end
    end
  end
end
