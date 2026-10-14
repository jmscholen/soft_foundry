# frozen_string_literal: true

require_relative "test_helper"

# changes/factory-readiness: REQ-FR-001 (UTF-8 reads).
class Utf8ReadsTest < Minitest::Test
  include FoundryFixture

  # The process locale decides Encoding.default_external; a C locale makes
  # it US-ASCII, and File.read then yields strings that raise on the first
  # regex match against a non-ASCII byte.
  def with_ascii_default
    saved = Encoding.default_external
    verbose = $VERBOSE
    $VERBOSE = nil
    Encoding.default_external = Encoding::US_ASCII
    yield
  ensure
    Encoding.default_external = saved
    $VERBOSE = verbose
  end

  def with_intake(text)
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      complete_phase!(record, "intake", sha: head(dir))
      File.binwrite(File.join(record.phase_dir(plane.phase("intake")), "request.md"), text)
      yield dir, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def test_gate_and_advisory_read_record_files_as_utf8_whatever_the_locale
    with_intake("# Intake\n\ninit → change new → gate\n".b) do |_dir, record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
        assert_kind_of Array, SoftFoundry::Advisory.new(record).notices
      end
    end
  end

  def test_invalid_bytes_are_scrubbed_not_raised
    with_intake("# Intake\n\xFF\xFE broken TBD here\n".b) do |_dir, _record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        check = result.checks.find { |c| c.name == "no placeholders" }
        assert_equal :fail, check.outcome, "the placeholder is still found after scrubbing"
        assert_includes check.detail, "request.md"
      end
    end
  end

  def test_read_text_returns_utf8_under_any_locale
    Dir.mktmpdir do |dir|
      path = File.join(dir, "t.md")
      File.binwrite(path, "caf\xC3\xA9 \xFF".b)
      with_ascii_default do
        text = SoftFoundry.read_text(path)
        assert_equal Encoding::UTF_8, text.encoding
        assert text.valid_encoding?
        assert_includes text, "café"
      end
    end
  end
end

# REQ-FR-002: the specification is locked on the gated track from the
# commit that recorded it, and evidence produced before a specification
# rerun is stale.
class GatedSpecificationLockTest < Minitest::Test
  include FoundryFixture

  def with_change
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c2", control_plane: plane, branch: "change/c2")
      commit_all(dir, "scaffold c2")
      yield dir, plane, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def check(gate, phase, name) = gate.evaluate(phase).checks.find { |c| c.name == name }

  def test_specification_is_locked_from_the_commit_that_recorded_it
    with_change do |dir, plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      commit_all(dir, "specified")
      lock = head(dir)
      c = check(gate, "specify", "specification locked")
      assert_equal :pass, c.outcome, c.detail
      assert_includes c.detail, lock[0, 12]

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      c = check(gate, "specify", "specification locked")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "requirements.yml"
      assert_includes c.detail, "rerun the specification phase"
      assert gate.evaluate("specify").failed?

      commit_all(dir, "edit the spec after the lock")
      assert_equal :fail, check(gate, "specify", "specification locked").outcome, "a committed edit is still an edit after the lock"
    end
  end

  def test_an_uncommitted_specification_is_not_locked_yet
    with_change do |dir, _plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      c = check(gate, "specify", "specification locked")
      assert_equal :warn, c.outcome
      assert_includes c.detail, "not yet locked"
      refute gate.evaluate("specify").failed?
    end
  end

  def test_evidence_recorded_before_a_specification_rerun_is_stale
    with_change do |dir, plane, record, gate|
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..verify
      commit_all(dir, "through verification")
      refute gate.evaluate("verify").stale?, "evidence recorded with the specification in the same commit is current"
      assert_equal :pass, check(gate, "specify", "specification locked").outcome

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      complete_phase!(record, "specify", sha: head(dir))
      commit_all(dir, "re-record the specification")
      assert_equal :pass, check(gate, "specify", "specification locked").outcome, "the rerun re-binds the lock"
      c = check(gate, "verify", "evidence current")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "specification"
      assert gate.evaluate("verify").stale?
    end
  end
end

# REQ-FR-003: every commit-bound phase completed without `phase run` is
# advised, not only review and judgment.
class FreshContextAdvisoryTest < Minitest::Test
  include FoundryFixture

  def fresh_context!(record, phase_id)
    phase = record.control_plane.phase(phase_id)
    h = record.handoff(phase)
    h["executed_by"] = { "runner" => "soft-foundry phase run", "shell" => "claude", "fresh_context" => true }
    File.write(record.handoff_path(phase), YAML.dump(h))
  end

  def test_verification_evaluation_and_attack_completed_in_session_are_advised
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c3", control_plane: plane)
      plane.phases.take(9).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..attack
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.message.include?("without `soft-foundry phase run`") }
      assert_equal %w[verification evaluation attack], notices.map(&:area)
      assert_includes notices[0].message, "06-verification"
      assert_includes notices[2].message, "08-attack"

      fresh_context!(record, "verify")
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.message.include?("without `soft-foundry phase run`") }
      assert_equal %w[evaluation attack], notices.map(&:area)
    end
  end

  def test_the_evidence_skills_say_they_prefer_a_fresh_session
    %w[verification evaluation adversarial-testing].each do |skill|
      text = SoftFoundry.read_text(File.join(REPO_ROOT, ".ai/skills", skill, "SKILL.md"))
      assert_includes text, "phase run", skill
    end
  end
end

# REQ-FR-007: which phases a change may waive depends on its declared
# risk; review and judgment are never waived; a change closes only with a
# judgment.
class WaiversByRiskTest < Minitest::Test
  include FoundryFixture

  def with_waivers(risk, skipped)
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "w1", control_plane: plane)
      path = File.join(record.dir, "metadata.yml")
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      m["risk"] = risk
      m["skipped_phases"] = skipped.map { |p| { "phase" => p, "rationale" => "harness test" } }
      File.write(path, YAML.dump(m))
      complete_phase!(record, "intake", sha: head(dir))
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("intake")
      yield result.checks.find { |c| c.name == "waivers permitted" }, result
    end
  end

  def test_the_repository_declares_what_each_risk_may_waive
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    assert_equal %w[discover specify threat_model plan attack learn], plane.waivable_by_risk("low")
    assert_equal %w[discover plan], plane.waivable_by_risk("medium")
    assert_equal [], plane.waivable_by_risk("high")
    assert_equal [], plane.waivable_by_risk("TBD")
    assert_equal [], plane.waivable_by_risk(nil)
  end

  def test_a_waiver_the_risk_allows_passes_and_one_it_does_not_fails
    with_waivers("low", %w[threat_model attack]) do |check, result|
      assert_equal :pass, check.outcome, check.detail
      refute result.failed?
    end
    with_waivers("medium", %w[threat_model]) do |check, result|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "threat_model"
      assert_includes check.detail, "medium"
      assert result.failed?
    end
    with_waivers("Low", %w[plan]) { |check, _| assert_equal :pass, check.outcome, "risk is matched case-insensitively" }
  end

  def test_review_and_judgment_are_never_waived
    with_waivers("low", %w[judge]) do |check, _|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "judge"
      assert_includes check.detail, "never"
    end
    with_waivers("high", %w[review]) { |check, _| assert_equal :fail, check.outcome }
  end

  def test_an_unclassified_risk_waives_only_optional_phases
    with_waivers("TBD", %w[discover]) do |check, _|
      assert_equal :fail, check.outcome
      assert_includes check.detail, "risk"
    end
    with_waivers("TBD", %w[document]) { |check, _| assert_equal :pass, check.outcome }
    with_waivers("medium", []) { |check, _| assert_equal :pass, check.outcome }
  end

  def test_check_rejects_a_waiver_rule_naming_judge_review_or_an_unknown_phase
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/workflow.yml")
      wf = YAML.safe_load_file(path)
      wf["waivable_by_risk"] = { "low" => %w[judge nowhere], "medium" => [] }
      File.write(path, YAML.dump(wf))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.select { |f| f.level == :error }.map(&:message)
      assert messages.any? { |m| m.include?("waivable_by_risk") && m.include?("judge") }, messages.inspect
      assert messages.any? { |m| m.include?("waivable_by_risk") && m.include?("nowhere") }, messages.inspect
    end
  end

  def test_change_close_refuses_without_a_completed_judgment_unless_forced
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/w2")
      cli(dir, "change", "new", "w2", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "w2", control_plane: SoftFoundry::ControlPlane.new(dir))
      path = File.join(record.dir, "metadata.yml")
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      m["risk"] = "low"
      m["skipped_phases"] = %w[discover specify threat_model plan attack learn].map { |p| { "phase" => p, "rationale" => "low risk" } }
      File.write(path, YAML.dump(m))
      commit_all(dir, "record w2")
      %w[intake implement verify evaluate review].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "through review")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/w2", "-m", "merge w2")

      refute record.reached_lifecycle_end?, "judgment is never a waived end"
      code, out = cli(dir, "change", "close", "w2")
      assert_equal 1, code, out
      assert_includes out, "14-judgment"
      assert_includes out, "--force"
      refute_equal "closed", record.metadata["status"]

      code, out = cli(dir, "change", "close", "w2", "--force")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
    end
  end
end

# REQ-FR-004 and MIT-001: the packaged policy is block mode, and the guard
# refuses writes to its own configuration from every skill.
class GuardBlockModeTest < Minitest::Test
  include FoundryFixture

  def with_change(phase: "implement")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/g1")
      cli(dir, "change", "new", "g1")
      meta = File.join(dir, "changes", "g1", "metadata.yml")
      File.write(meta, SoftFoundry.read_text(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: #{phase}"))
      commit_all(dir, "record")
      yield dir, SoftFoundry::Guard.new(dir)
    end
  end

  def guard_cli(dir, payload, env: {})
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "SOFT_FOUNDRY_GUARD" => nil }.merge(env)) do
      code = SoftFoundry::CLI.new(["guard"], out: out, err: err, input: StringIO.new(JSON.generate(payload)), root: dir).run
    end
    [code, out.string + err.string]
  end

  SELF = %w[.soft-foundry/enforcement.yml .ai/policies/enforcement.yml .claude/settings.json .claude/settings.local.json .codex/hooks.json].freeze

  def test_the_packaged_policy_is_block_mode
    with_fixture_repo do |dir|
      assert_equal ["block", "repository policy (.ai/policies/enforcement.yml)"], SoftFoundry::Guard.mode(dir, env: {})
    end
  end

  def test_the_guards_own_configuration_is_denied_to_every_skill
    %w[implement review].each do |phase|
      with_change(phase: phase) do |dir, guard|
        SELF.each do |path|
          d = guard.decide("Edit", { "file_path" => path })
          assert d.violation?, "#{phase}: Edit #{path}"
          assert_includes d.reason, "guard's own configuration"
          assert guard.decide("Write", { "file_path" => File.join(dir, path) }).violation?, "#{phase}: Write #{path}"
        end
        assert guard.decide("Bash", { "command" => "printf 'guard: {mode: off}' > .soft-foundry/enforcement.yml" }).violation?
        assert guard.decide("Bash", { "command" => "rm .claude/settings.json" }).violation?
        assert_equal :allow, guard.decide("Bash", { "command" => "cat README.md" }).outcome
      end
    end
  end

  def test_a_block_mode_refusal_names_the_override_without_prescribing_it
    with_change do |dir, _guard|
      code, out = guard_cli(dir, { "tool_name" => "Edit", "tool_input" => { "file_path" => ".ai/rules/ruby.md" } })
      assert_equal 2, code, out
      assert_includes out, "✗ fail guard: Edit .ai/rules/ruby.md"
      assert_includes out, "mode: block"
      assert_includes out, "machine-local override"
      refute_includes out, "mode: off"
      code, = guard_cli(dir, { "tool_name" => "Edit", "tool_input" => { "file_path" => ".ai/rules/ruby.md" } }, env: { "SOFT_FOUNDRY_GUARD" => "warn" })
      assert_equal 0, code, "the environment still wins"
    end
  end

  def test_doctor_and_hooks_install_report_block_mode
    with_fixture_repo do |dir|
      _, out = cli(dir, "hooks", "install", "--claude")
      assert_includes out, "guard mode: block (repository policy (.ai/policies/enforcement.yml))"
      _, out = cli(dir, "doctor")
      assert_includes out, "mode: block, repository policy (.ai/policies/enforcement.yml)"
    end
  end
end

# REM-001 (from 06-verification's notes): under block mode the evidence
# skills could not run tests or the tool, because the guard refused any
# shell command naming a deny_write path even when the skill may read it;
# and a stale complete phase could not be rerun by `phase run`.
class GuardShellNamingTest < Minitest::Test
  include FoundryFixture

  def with_phase(phase)
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/s1")
      cli(dir, "change", "new", "s1")
      meta = File.join(dir, "changes", "s1", "metadata.yml")
      File.write(meta, SoftFoundry.read_text(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: #{phase}"))
      commit_all(dir, "record")
      yield SoftFoundry::Guard.new(dir)
    end
  end

  def bash(guard, command) = guard.decide("Bash", { "command" => command })

  def test_a_skill_may_name_in_a_shell_command_what_it_may_read
    with_phase("verify") do |guard|
      assert_equal :allow, bash(guard, "ruby -Ilib -Itest test/app_test.rb").outcome
      assert_equal :allow, bash(guard, "ruby -Ilib exe/soft-foundry gate verify").outcome
      assert_equal :allow, bash(guard, "cat .ai/rules/testing.md").outcome
      d = bash(guard, "cat .ai/harness-evals/README.md")
      assert d.violation?, "deny_read still refuses"
      d = bash(guard, "sed -i s/x/y/ .ai/policies/budget.yml")
      assert d.violation?, "protected policy is refused whatever the read set says"
      assert bash(guard, "echo off > .soft-foundry/enforcement.yml").violation?
    end
    with_phase("implement") do |guard|
      assert_equal :allow, bash(guard, "cat .ai/rules/ruby.md").outcome, "implementation reads the rules it works under"
      assert bash(guard, "rm -rf .ai/policies").violation?
      assert bash(guard, "cat .ai/harness-evals/cases/x.yml").violation?
    end
    with_phase("review") do |guard|
      assert_equal :allow, bash(guard, "ruby -Ilib -Itest test/gate_test.rb").outcome
      assert_equal :allow, bash(guard, "git diff main -- lib/soft_foundry/gate.rb").outcome
    end
  end

  def test_a_stale_complete_phase_may_be_rerun_by_phase_run
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/s2")
      cli(dir, "change", "new", "s2")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.new(dir, "s2", control_plane: plane)
      commit_all(dir, "record")
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..verify
      commit_all(dir, "through verification")
      runner = SoftFoundry::PhaseRunner.new(dir, plane: plane, git: SoftFoundry::Git.new(dir), record: record)
      assert_includes runner.refusal(plane.phase("verify")), "already complete"

      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed after verification")
      assert_nil runner.refusal(plane.phase("verify")), "stale evidence may be redone"
      code, out = cli(dir, "phase", "run", "verify", "--dry-run")
      assert_equal 0, code, out
      assert_includes out, "would run verify of s2"
    end
  end
end

# REM-002 (from 08-attack, ATK-F1 and ATK-F2): the shell heuristic resolved
# only tokens that spelled a path in full. A `cd` into the directory, a
# glob, or a symlink reached the guard's own configuration and the eval
# cases. The guard now follows `cd` within a command, expands globs, and
# resolves symlinks before deciding; the whole .soft-foundry directory is
# the guard's own.
class GuardIndirectionTest < Minitest::Test
  include FoundryFixture

  def with_phase(phase)
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/i1")
      cli(dir, "change", "new", "i1")
      meta = File.join(dir, "changes", "i1", "metadata.yml")
      File.write(meta, SoftFoundry.read_text(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: #{phase}"))
      commit_all(dir, "record")
      yield dir, SoftFoundry::Guard.new(dir)
    end
  end

  def bash(guard, command) = guard.decide("Bash", { "command" => command })

  def test_cd_relative_names_are_resolved
    with_phase("implement") do |_dir, guard|
      d = bash(guard, "mkdir -p .soft-foundry && cd .soft-foundry && printf 'guard: {mode: warn}' > enforcement.yml")
      assert d.violation?
      assert_includes d.reason, "guard's own configuration"
      assert bash(guard, "cd .soft-foundry; echo x > enforcement.yml").violation?
      assert bash(guard, "cd .ai && ls harness-evals").violation?
      assert bash(guard, "cd .ai/harness-evals && cat README.md").violation?
      assert bash(guard, "cd .ai && cd policies && cat budget.yml").violation?
      assert_equal :allow, bash(guard, "cd .ai && cat rules/ruby.md").outcome
      assert_equal :allow, bash(guard, "cd lib && ruby app.rb").outcome
    end
  end

  def test_globs_are_expanded_before_deciding
    with_phase("implement") do |_dir, guard|
      assert bash(guard, "cat .ai/harness-*/cases/*").violation?
      assert bash(guard, "cat .ai/harness-ev*").violation?
      assert bash(guard, "cat .ai/pol*/budget.yml").violation?
      assert_equal :allow, bash(guard, "ls lib/*.rb").outcome
      assert_equal :allow, bash(guard, "cat .ai/rules/*.md").outcome
    end
  end

  def test_the_guard_configuration_directory_is_its_own
    with_phase("verify") do |_dir, guard|
      assert bash(guard, "cat .soft-foundry/guard.log").violation?
      assert guard.decide("Write", { "file_path" => ".soft-foundry/anything.yml" }).violation?
      assert guard.decide("Write", { "file_path" => ".soft-foundry/enforcement.yml" }).violation?
    end
  end

  def test_symlinks_are_resolved_before_deciding
    with_phase("implement") do |dir, guard|
      File.symlink("../.ai/policies/enforcement.yml", File.join(dir, "lib", "x.yml"))
      d = guard.decide("Edit", { "file_path" => "lib/x.yml" })
      assert d.violation?, "a link in the write set that points at the policy is the policy"
      assert_includes d.reason, "guard's own configuration"
      File.symlink("../.ai", File.join(dir, "lib", "plane"))
      d = guard.decide("Write", { "file_path" => "lib/plane/rules/ruby.md" })
      assert d.violation?
      assert_includes d.reason, "deny_write"
      assert bash(guard, "cat lib/plane/harness-evals/README.md").violation?
      assert_equal :allow, guard.decide("Edit", { "file_path" => "lib/app.rb" }).outcome
    end
  end

  def test_a_case_file_has_a_size_cap
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      big = { "id" => "big", "kind" => "gate", "description" => "x", "record" => { "files" => { "00-intake/request.md" => "a" * 70_000 } },
              "expect" => { "phase" => "intake", "outcome" => "pass" } }
      File.write(File.join(dir, ".ai/harness-evals/cases/big.yml"), YAML.dump(big))
      problems = SoftFoundry::HarnessEval.lint(dir, plane)
      assert problems.any? { |p| p.include?("big.yml") && p.include?("bytes") }, problems.inspect
    end
  end
end

# REM-003 (from the second 08-attack, ATK-F5, ATK-F6, part of ATK-F7): the
# guard did not follow `cd ..` back to the root, raised (and so failed
# open) on a `~user`, `~+`, or NUL-bearing token, ignored brace expansion,
# and left the Grep and Glob tools unguarded.
class GuardFailClosedTest < Minitest::Test
  include FoundryFixture

  def with_phase(phase)
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/f1")
      cli(dir, "change", "new", "f1")
      meta = File.join(dir, "changes", "f1", "metadata.yml")
      File.write(meta, SoftFoundry.read_text(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: #{phase}"))
      commit_all(dir, "record")
      yield dir, SoftFoundry::Guard.new(dir)
    end
  end

  def bash(guard, command) = guard.decide("Bash", { "command" => command })

  def guard_cli(dir, payload, env: {})
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "SOFT_FOUNDRY_GUARD" => nil }.merge(env)) do
      code = SoftFoundry::CLI.new(["guard"], out: out, err: err, input: StringIO.new(JSON.generate(payload)), root: dir).run
    end
    [code, out.string + err.string]
  end

  def test_cd_back_to_the_root_and_beyond_is_followed
    with_phase("implement") do |_dir, guard|
      assert bash(guard, "cd lib && cd .. && cd .ai/policies && sed -i s/block/warn/ enforcement.yml").violation?
      assert bash(guard, "cd lib && cd ../.ai && cat harness-evals/README.md").violation?
      assert bash(guard, "cd lib && cd .. && cat .ai/harness-evals/README.md").violation?
      assert_equal :allow, bash(guard, "cd lib && cd .. && cat README.md").outcome
      assert_equal :allow, bash(guard, "cd lib && cd ../lib && ruby app.rb").outcome
      assert bash(guard, "cd /tmp && cat #{File.join(guard.send(:real_root), '.ai/policies/budget.yml')}").violation?, "an absolute path after leaving the root is still seen"
    end
  end

  def test_brace_expansion_is_followed
    with_phase("implement") do |_dir, guard|
      assert bash(guard, "cat .ai/{policies,rules}/budget.yml").violation?
      assert bash(guard, "ls .ai/harness-{evals,x}").violation?
      assert_equal :allow, bash(guard, "cat .ai/rules/{ruby,git}.md").outcome
    end
  end

  def test_a_token_the_guard_cannot_resolve_is_refused_not_raised
    with_phase("implement") do |dir, guard|
      ["echo ~nosuchuser/x > .ai/policies/enforcement.yml", "cat ~+/x", "cat a\u0000b"].each do |command|
        d = bash(guard, command)
        assert d.violation?, command.inspect
        assert_includes d.reason, "could not be decided"
      end
      d = guard.decide("Edit", { "file_path" => "lib/a\u0000b.rb" })
      assert d.violation?
      code, out = guard_cli(dir, { "tool_name" => "Bash", "tool_input" => { "command" => "cat ~nosuchuser/x" } })
      assert_equal 2, code, "block mode refuses what it cannot decide"
      assert_includes out, "✗ fail guard:"
      code, out = guard_cli(dir, { "tool_name" => "Bash", "tool_input" => { "command" => "cat ~nosuchuser/x" } }, env: { "SOFT_FOUNDRY_GUARD" => "warn" })
      assert_equal 0, code
      assert_includes out, "! warn guard:"
    end
  end

  def test_grep_and_glob_are_guarded_by_path
    with_phase("implement") do |_dir, guard|
      assert guard.decide("Grep", { "pattern" => "x", "path" => ".ai/harness-evals" }).violation?
      assert guard.decide("Grep", { "pattern" => "x", "path" => ".ai/harness-evals/cases/a.yml" }).violation?
      assert guard.decide("Glob", { "pattern" => ".ai/harness-evals/**/*.yml" }).violation?
      assert guard.decide("Glob", { "pattern" => "**/*.yml", "path" => ".ai/harness-evals/cases" }).violation?
      assert_equal :allow, guard.decide("Grep", { "pattern" => "x", "path" => "lib" }).outcome
      assert_equal :allow, guard.decide("Glob", { "pattern" => "lib/**/*.rb" }).outcome
      assert_equal :allow, guard.decide("Grep", { "pattern" => "x" }).outcome, "a search from the root is the documented limit, not a refusal"
    end
    assert_includes SoftFoundry::Hooks::GUARD_MATCHER, "Grep"
    assert_includes SoftFoundry::Hooks::GUARD_MATCHER, "Glob"
  end
end
