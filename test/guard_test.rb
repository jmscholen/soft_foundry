# frozen_string_literal: true

require_relative "test_helper"

# Runtime enforcement of skill permissions: `soft-foundry guard` as a
# PreToolUse hook, its mode resolution, the Claude settings install, and
# what `doctor` says about it.
class GuardTest < Minitest::Test
  include FoundryFixture

  # A change on its own branch parked at the implementation phase, so the
  # implementation skill's permissions apply.
  def with_implementing_change(slug = "c1", phase: "implement")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      meta = File.join(dir, "changes", slug, "metadata.yml")
      File.write(meta, File.read(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: #{phase}"))
      commit_all(dir, "record")
      yield dir, SoftFoundry::Guard.new(dir)
    end
  end

  def guard_cli(dir, payload, env: {})
    out = StringIO.new
    err = StringIO.new
    input = StringIO.new(payload.is_a?(String) ? payload : JSON.generate(payload))
    code = nil
    with_env({ "SOFT_FOUNDRY_GUARD" => nil }.merge(env)) do
      code = SoftFoundry::CLI.new(["guard"], out: out, err: err, input: input, root: dir).run
    end
    [code, out.string + err.string]
  end

  def edit(path) = { "tool_name" => "Edit", "tool_input" => { "file_path" => path } }
  def read(path) = { "tool_name" => "Read", "tool_input" => { "file_path" => path } }
  def bash(command) = { "tool_name" => "Bash", "tool_input" => { "command" => command } }

  # --- decisions ------------------------------------------------------------

  def test_implementation_may_write_app_and_tests_but_not_control_plane_docs_or_evidence
    with_implementing_change do |dir, guard|
      assert_equal :allow, guard.decide("Edit", { "file_path" => File.join(dir, "lib/app.rb") }).outcome
      assert_equal :allow, guard.decide("Write", { "file_path" => "test/app_test.rb" }).outcome
      assert_equal :allow, guard.decide("Edit", { "file_path" => "changes/c1/05-implementation/log.md" }).outcome

      d = guard.decide("Edit", { "file_path" => ".ai/rules/ruby.md" })
      assert d.violation?
      assert_includes d.reason, "deny_write"
      assert_equal "implementation", d.skill
      assert d.violation?, guard.decide("Write", { "file_path" => "docs/user/README.md" }).reason
      assert d.violation?, guard.decide("MultiEdit", { "file_path" => "changes/c1/06-verification/results.md" }).reason
      d = guard.decide("Write", { "file_path" => "README.md" })
      assert d.violation?
      assert_includes d.reason, "not in implementation's write set"
    end
  end

  def test_reads_are_checked_against_deny_read_only
    with_implementing_change do |dir, guard|
      assert_equal :allow, guard.decide("Read", { "file_path" => "Gemfile" }).outcome, "read lists are advisory"
      d = guard.decide("Read", { "file_path" => ".ai/harness-evals/README.md" })
      assert d.violation?
      assert_includes d.reason, "deny_read"
      assert guard.decide("Read", { "file_path" => "changes/c1/07-evaluation/evidence/x.log" }).violation?
    end
  end

  def test_bash_is_refused_only_when_it_names_a_denied_path
    with_implementing_change do |dir, guard|
      assert_equal :allow, guard.decide("Bash", { "command" => "bundle exec rake test" }).outcome
      assert_equal :allow, guard.decide("Bash", { "command" => "git commit -am 'x' && echo done" }).outcome
      assert_equal :allow, guard.decide("Bash", { "command" => "cat lib/app.rb > /dev/null" }).outcome
      d = guard.decide("Bash", { "command" => "rm -rf .ai/policies" })
      assert d.violation?
      assert_equal [".ai/policies"], d.paths
      assert guard.decide("Bash", { "command" => "echo hi >> changes/c1/13-review/functional.md" }).violation?
      assert guard.decide("Bash", { "command" => "sed -i '' 's/a/b/' \"docs/user/README.md\"" }).violation?
    end
  end

  def test_writes_outside_the_repository_are_violations
    with_implementing_change do |_dir, guard|
      d = guard.decide("Write", { "file_path" => "/etc/hosts" })
      assert d.violation?
      assert_includes d.reason, "outside the repository"
      assert guard.decide("Edit", { "file_path" => "../elsewhere.rb" }).violation?
    end
  end

  def test_nothing_is_guarded_without_a_change_record_or_after_it_closes
    with_fixture_repo do |dir|
      guard = SoftFoundry::Guard.new(dir)
      d = guard.decide("Edit", { "file_path" => ".ai/rules/ruby.md" })
      assert_equal :allow, d.outcome
      assert_includes d.reason, "no change record for branch 'main'"
    end
    with_implementing_change do |dir, guard|
      meta = File.join(dir, "changes/c1/metadata.yml")
      File.write(meta, File.read(meta).sub(/^status: in_progress/, "status: closed"))
      d = guard.decide("Edit", { "file_path" => ".ai/rules/ruby.md" })
      assert_equal :allow, d.outcome
      assert_includes d.reason, "is closed"
    end
  end

  def test_the_phase_selects_the_skill
    with_implementing_change("c1", phase: "verify") do |_dir, guard|
      d = guard.decide("Edit", { "file_path" => "lib/app.rb" })
      assert d.violation?, "verification may not repair the code under test"
      assert_equal "verification", d.skill
      assert_equal :allow, guard.decide("Write", { "file_path" => "changes/c1/06-verification/results.md" }).outcome
    end
  end

  def test_an_exploring_change_uses_the_stage_skill
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/it1")
      cli(dir, "change", "new", "it1", "--track", "iterative")
      commit_all(dir, "record")
      guard = SoftFoundry::Guard.new(dir)
      d = guard.decide("Edit", { "file_path" => "changes/it1/02-specification/specification.md" })
      assert_equal :allow, d.outcome, "the draft specification is writable while exploring"
      assert_equal "exploration", d.skill
      assert_equal :allow, guard.decide("Write", { "file_path" => "changes/it1/exploration/iterations.yml" }).outcome
      assert guard.decide("Write", { "file_path" => "changes/it1/06-verification/results.md" }).violation?
    end
  end

  # --- mode ------------------------------------------------------------------

  def test_mode_comes_from_env_then_local_override_then_policy_then_default
    with_fixture_repo do |dir|
      assert_equal ["warn", "repository policy (.ai/policies/enforcement.yml)"], SoftFoundry::Guard.mode(dir, env: {})
      File.delete(File.join(dir, ".ai/policies/enforcement.yml"))
      assert_equal ["warn", "default"], SoftFoundry::Guard.mode(dir, env: {})
      FileUtils.mkdir_p(File.join(dir, ".soft-foundry"))
      File.write(File.join(dir, ".soft-foundry/enforcement.yml"), YAML.dump("guard" => { "mode" => "block" }))
      assert_equal "block", SoftFoundry::Guard.mode(dir, env: {}).first
      assert_equal "off", SoftFoundry::Guard.mode(dir, env: { "SOFT_FOUNDRY_GUARD" => "off" }).first
      assert_equal "block", SoftFoundry::Guard.mode(dir, env: { "SOFT_FOUNDRY_GUARD" => "bogus" }).first, "an unknown value is ignored"
    end
  end

  def test_check_rejects_an_unknown_enforcement_mode
    with_fixture_repo do |dir|
      File.write(File.join(dir, ".ai/policies/enforcement.yml"), YAML.dump("guard" => { "mode" => "maybe" }))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.map(&:message)
      assert messages.any? { |m| m.include?("guard.mode 'maybe'") }, messages.inspect
    end
  end

  # --- the hook command --------------------------------------------------------

  def test_guard_command_warns_and_allows_by_default_and_logs_the_violation
    with_implementing_change do |dir, _guard|
      code, out = guard_cli(dir, edit(".ai/rules/ruby.md"))
      assert_equal 0, code
      assert_includes out, "! warn guard: Edit .ai/rules/ruby.md is in implementation's deny_write set"
      assert_includes out, "mode: warn"
      log = File.read(File.join(dir, ".soft-foundry/guard.log"))
      assert_includes log, "warn Edit skill=implementation paths=.ai/rules/ruby.md"

      code, out = guard_cli(dir, edit("lib/app.rb"))
      assert_equal 0, code
      assert_empty out, "an allowed call is silent"
    end
  end

  def test_guard_command_refuses_in_block_mode_with_exit_2
    with_implementing_change do |dir, _guard|
      code, out = guard_cli(dir, edit(".ai/rules/ruby.md"), env: { "SOFT_FOUNDRY_GUARD" => "block" })
      assert_equal 2, code
      assert_includes out, "✗ fail guard: Edit .ai/rules/ruby.md is in implementation's deny_write set"
      code, out = guard_cli(dir, bash("rm -rf .ai/policies"), env: { "SOFT_FOUNDRY_GUARD" => "block" })
      assert_equal 2, code
      assert_includes out, "Bash .ai/policies names a path implementation is denied"
      assert_equal 0, guard_cli(dir, bash("bundle exec rake test"), env: { "SOFT_FOUNDRY_GUARD" => "block" }).first
    end
  end

  def test_guard_command_is_silent_when_off_and_fails_closed_on_unreadable_input_in_block_mode
    with_implementing_change do |dir, _guard|
      code, out = guard_cli(dir, edit(".ai/rules/ruby.md"), env: { "SOFT_FOUNDRY_GUARD" => "off" })
      assert_equal 0, code
      assert_empty out
      code, out = guard_cli(dir, "not json", env: { "SOFT_FOUNDRY_GUARD" => "block" })
      assert_equal 2, code
      assert_includes out, "could not read the tool call"
      code, out = guard_cli(dir, "not json", env: { "SOFT_FOUNDRY_GUARD" => "warn" })
      assert_equal 0, code
      assert_includes out, "! warn guard: could not read the tool call"
    end
  end

  # --- install and doctor ------------------------------------------------------

  def test_hooks_install_claude_writes_the_guard_entry_idempotently_and_keeps_other_settings
    with_fixture_repo do |dir|
      settings = File.join(dir, ".claude/settings.json")
      FileUtils.mkdir_p(File.dirname(settings))
      File.write(settings, JSON.generate("permissions" => { "allow" => ["Bash(ls)"] }, "hooks" => { "PreToolUse" => [{ "matcher" => "Bash", "hooks" => [{ "type" => "command", "command" => "echo theirs" }] }] }))

      code, out = cli(dir, "hooks", "install", "--claude")
      assert_equal 0, code, out
      assert_includes out, "installed guard hook in .claude/settings.json"
      assert_includes out, "guard mode: warn"
      2.times { assert_equal 0, cli(dir, "hooks", "install", "--claude").first }

      data = JSON.parse(File.read(settings))
      assert_equal ["Bash(ls)"], data.dig("permissions", "allow")
      entries = data.dig("hooks", "PreToolUse")
      assert_equal 2, entries.size, "theirs plus exactly one of ours"
      assert_equal "echo theirs", entries.first.dig("hooks", 0, "command")
      ours = entries.last
      assert_equal SoftFoundry::Hooks::GUARD_MATCHER, ours["matcher"]
      assert_includes ours.dig("hooks", 0, "command"), "soft-foundry guard"
      assert_equal settings, SoftFoundry::Hooks.claude_installed?(dir)

      code, out = cli(dir, "hooks", "uninstall", "--claude")
      assert_equal 0, code, out
      data = JSON.parse(File.read(settings))
      assert_equal 1, data.dig("hooks", "PreToolUse").size
      assert_nil SoftFoundry::Hooks.claude_installed?(dir)
      assert_includes cli(dir, "hooks", "uninstall", "--claude").last, "no guard hook installed"
    end
  end

  def test_hooks_install_claude_local_targets_the_local_settings_file
    with_fixture_repo do |dir|
      code, out = cli(dir, "hooks", "install", "--claude", "--local")
      assert_equal 0, code, out
      assert File.file?(File.join(dir, ".claude/settings.local.json"))
      refute File.exist?(File.join(dir, ".claude/settings.json"))
    end
  end

  def test_hooks_install_claude_refuses_invalid_settings
    with_fixture_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".claude"))
      File.write(File.join(dir, ".claude/settings.json"), "{ not json")
      code, out = cli(dir, "hooks", "install", "--claude")
      refute_equal 0, code
      assert_includes out, "not valid JSON"
    end
  end

  def test_doctor_reports_the_guard_hook_and_mode
    with_fixture_repo do |dir|
      _, out = cli(dir, "doctor")
      assert_includes out, "✗ fail guard hook (claude: not installed, codex: not installed; mode: warn, repository policy (.ai/policies/enforcement.yml)); install with `soft-foundry hooks install --claude` or `--codex`"
      cli(dir, "hooks", "install", "--claude")
      _, out = cli(dir, "doctor")
      assert_includes out, "✓ pass guard hook (claude: installed, codex: not installed; mode: warn"
    end
  end
end
