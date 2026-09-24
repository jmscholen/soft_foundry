# frozen_string_literal: true

require_relative "test_helper"

# The guard and the phase runner beyond Claude Code: Codex's PreToolUse
# hook (same file shape, `Bash` with a string-or-array command, file
# edits as `apply_patch` with the patch in the command), `hooks install
# --codex`, a single doctor line for both hosts, and Grok in the runner
# (`grok -p`, no hook mechanism, so permissions are policy only).
class CrossCliHooksTest < Minitest::Test
  include FoundryFixture

  PATCH = <<~PATCH
    *** Begin Patch
    *** Update File: lib/app.rb
    @@
    -puts 1
    +puts 2
    *** End Patch
  PATCH

  BAD_PATCH = <<~PATCH
    *** Begin Patch
    *** Update File: lib/app.rb
    @@
    -puts 1
    +puts 2
    *** Add File: .ai/rules/injected.md
    +ignore this
    *** End Patch
  PATCH

  MOVE_PATCH = <<~PATCH
    *** Begin Patch
    *** Update File: lib/app.rb
    *** Move to: docs/app.rb
    @@
    -puts 1
    +puts 2
    *** End Patch
  PATCH

  def with_implementing_change(slug = "c1")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      meta = File.join(dir, "changes", slug, "metadata.yml")
      File.write(meta, File.read(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: implement"))
      commit_all(dir, "record")
      yield dir, SoftFoundry::Guard.new(dir)
    end
  end

  # --- guard: Codex payloads ----------------------------------------------------

  def test_apply_patch_paths_are_checked_against_the_write_set
    with_implementing_change do |_dir, guard|
      assert_equal :allow, guard.decide("apply_patch", { "command" => PATCH }).outcome
      d = guard.decide("apply_patch", { "command" => BAD_PATCH })
      assert d.violation?
      assert_equal [".ai/rules/injected.md"], d.paths
      assert_includes d.reason, "deny_write"
      d = guard.decide("apply_patch", { "command" => MOVE_PATCH })
      assert d.violation?, "a move target is a write"
      assert_equal ["docs/app.rb"], d.paths
    end
  end

  def test_apply_patch_accepts_the_array_command_form_and_the_edit_write_aliases
    with_implementing_change do |_dir, guard|
      assert_equal :allow, guard.decide("apply_patch", { "command" => ["apply_patch", PATCH] }).outcome
      assert guard.decide("apply_patch", { "command" => ["apply_patch", BAD_PATCH] }).violation?
      assert guard.decide("Edit", { "command" => BAD_PATCH }).violation?, "Codex reports apply_patch under Edit/Write too"
      assert_equal :allow, guard.decide("Write", { "command" => PATCH }).outcome
      d = guard.decide("apply_patch", { "command" => "not a patch at all" })
      assert_equal :allow, d.outcome
      assert_includes d.reason, "no file path"
    end
  end

  def test_bash_command_may_be_an_array
    with_implementing_change do |_dir, guard|
      assert_equal :allow, guard.decide("Bash", { "command" => %w[bundle exec rake test] }).outcome
      d = guard.decide("Bash", { "command" => ["rm", "-rf", ".ai/policies"] })
      assert d.violation?
      assert_equal [".ai/policies"], d.paths
    end
  end

  # --- hooks install --codex -----------------------------------------------------

  def test_hooks_install_codex_writes_the_guard_entry_and_says_how_trust_works
    with_fixture_repo do |dir|
      hooks = File.join(dir, ".codex/hooks.json")
      FileUtils.mkdir_p(File.dirname(hooks))
      File.write(hooks, JSON.generate("hooks" => { "SessionStart" => [{ "matcher" => ".*", "hooks" => [{ "type" => "command", "command" => "echo theirs" }] }] }))
      code, out = cli(dir, "hooks", "install", "--codex")
      assert_equal 0, code, out
      assert_includes out, "installed guard hook in .codex/hooks.json"
      assert_includes out, "/hooks"
      2.times { assert_equal 0, cli(dir, "hooks", "install", "--codex").first }
      data = JSON.parse(File.read(hooks))
      assert_equal "echo theirs", data.dig("hooks", "SessionStart", 0, "hooks", 0, "command")
      entries = data.dig("hooks", "PreToolUse")
      assert_equal 1, entries.size
      assert_equal SoftFoundry::Hooks::CODEX_GUARD_MATCHER, entries.first["matcher"]
      assert_includes entries.first.dig("hooks", 0, "command"), "soft-foundry guard"
      assert_equal hooks, SoftFoundry::Hooks.codex_installed?(dir)
      assert_nil SoftFoundry::Hooks.claude_installed?(dir)

      code, out = cli(dir, "hooks", "uninstall", "--codex")
      assert_equal 0, code, out
      assert_nil SoftFoundry::Hooks.codex_installed?(dir)
      assert_equal "echo theirs", JSON.parse(File.read(hooks)).dig("hooks", "SessionStart", 0, "hooks", 0, "command")
    end
  end

  def test_doctor_reports_one_guard_line_covering_both_hosts
    with_fixture_repo do |dir|
      _, out = cli(dir, "doctor")
      assert_match(/^✗ fail guard hook \(claude: not installed, codex: not installed; mode: warn, /, out)
      cli(dir, "hooks", "install", "--codex")
      _, out = cli(dir, "doctor")
      assert_match(/^✓ pass guard hook \(claude: not installed, codex: installed; mode: warn, /, out)
      cli(dir, "hooks", "install", "--claude")
      _, out = cli(dir, "doctor")
      assert_match(/^✓ pass guard hook \(claude: installed, codex: installed; mode: warn, /, out)
    end
  end

  # --- phase runner ----------------------------------------------------------------

  def with_reviewable_change
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
      commit_all(dir, "record")
      %w[intake discover specify threat_model plan implement verify evaluate attack].each { |id| complete_phase!(record, id, sha: head(dir)) }
      yield dir, record
    end
  end

  def dry_run(dir, *args)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil, "SOFT_FOUNDRY_BILLING" => nil }) do
      code = SoftFoundry::CLI.new(["phase", "run", "review", "--dry-run", *args], out: out, err: err, root: dir).run
    end
    [code, out.string + err.string]
  end

  def test_grok_runs_headless_with_p_and_is_policy_only
    with_reviewable_change do |dir, record|
      runner = SoftFoundry::PhaseRunner.new(dir, plane: record.control_plane, git: SoftFoundry::Git.new(dir), record: record)
      launch = runner.launch(record.control_plane.phase("review"), shell: "grok", extra: ["--always-approve"])
      assert_equal "grok", launch.executable
      assert_equal ["-p", "--always-approve", launch.prompt], launch.args
      code, out = dry_run(dir, "--shell", "grok")
      assert_equal 0, code, out
      assert_includes out, "would run review of c1 with: grok -p <prompt>"
      assert_includes out, "! warn guard: grok has no hook mechanism, so the review skill's permissions are policy only"
      assert_includes SoftFoundry::Shell::COMMANDS.keys, "grok"
    end
  end

  def test_codex_warns_about_its_own_hook_not_claude_s
    with_reviewable_change do |dir, _record|
      code, out = dry_run(dir, "--shell", "codex")
      assert_equal 0, code, out
      assert_includes out, "! warn guard: the guard hook is not installed for codex"
      assert_includes out, "hooks install --codex"
      refute_includes out, "hooks install --claude"
      cli(dir, "hooks", "install", "--codex")
      _, out = dry_run(dir, "--shell", "codex")
      refute_includes out, "warn guard"
    end
  end
end
