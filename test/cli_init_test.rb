# frozen_string_literal: true

require_relative "test_helper"

class CLIInitTest < Minitest::Test
  include FoundryFixture

  def manifest(dir) = SoftFoundry::Manifest.load(dir)

  def test_clean_install_installs_canonical_set_and_manifest # AC-001, AC-010, AC-016
    with_target_repo do |dir|
      code, out = init(dir)
      assert_equal 0, code, out
      installed = Dir.glob(".ai/**/*", File::FNM_DOTMATCH, base: dir).select { |p| File.file?(File.join(dir, p)) } - [".ai/manifest.yml"]
      assert_equal source.paths.select { |p| p.start_with?(".ai/") }.sort, installed.sort
      m = manifest(dir)
      installed.each { |p| assert m.owned?(p, File.binread(File.join(dir, p))), "#{p} not in manifest" unless p == ".ai/repository.yml" }
      refute m.include?(".ai/repository.yml")
      assert_equal "puts 1\n", File.read(File.join(dir, "lib/app.rb"))
      assert File.exist?(File.join(dir, "changes/README.md"))
      assert File.exist?(File.join(dir, "docs/user/README.md"))
      assert_includes File.read(File.join(dir, ".gitignore")), ".soft-foundry/"
      assert_includes File.read(File.join(dir, "AGENTS.md")), SoftFoundry::AgentFiles::BEGIN_MARKER
      assert_includes File.read(File.join(dir, "CLAUDE.md")), SoftFoundry::AgentFiles::BEGIN_MARKER
      # AC-010 predates the maturity-onboarding change: init now runs a free
      # deterministic maturity scan by default (--maturity=scan), so a fresh
      # install is assessed, not left at the pristine unassessed template.
      # See changes/maturity-onboarding/.
      assert_equal true, YAML.safe_load_file(File.join(dir, ".ai/repository.yml")).dig("repository", "assessed")
      assert_equal ["README.md"], Dir.children(File.join(dir, ".ai/harness-evals"))
      assert_includes out, "check: ok"
      ascii = out.gsub(/[^ -~\n]/, "")
      assert_match(/^created +\.ai\/workflow\.yml/, ascii)
    end
  end

  def test_refuses_non_git_target_without_flag # AC-002
    with_target_repo(git: false) do |dir|
      code, out = init(dir)
      assert_equal 1, code
      assert_includes out, "not inside a Git work tree"
      refute File.exist?(File.join(dir, ".ai"))
      code, = init(dir, "--allow-non-git")
      assert_equal 0, code
    end
  end

  def test_second_run_skips_everything_and_leaves_tree_clean # AC-003
    with_target_repo do |dir|
      init(dir)
      commit_all(dir)
      mtimes = Dir.glob("**/*", File::FNM_DOTMATCH, base: dir).reject { |p| p.start_with?(".git") }.to_h { |p| [p, File.lstat(File.join(dir, p)).mtime] }
      code, out = init(dir)
      assert_equal 0, code, out
      assert_match(/summary: created 0, updated 0, skipped \d+, conflict 0, forced 0/, out)
      refute_match(/^(created|updated|conflict|forced) /, out)
      assert_equal "", sh(dir, "git", "status", "--porcelain")
      mtimes.each { |p, t| assert_equal t, File.lstat(File.join(dir, p)).mtime, "#{p} was rewritten" }
    end
  end

  def test_agents_and_claude_preserved_and_block_appended_once # AC-004, AC-005
    with_target_repo do |dir|
      File.write(File.join(dir, "AGENTS.md"), "# Ours\nKeep this.\n")
      File.write(File.join(dir, "CLAUDE.md"), "Custom Claude notes\n")
      code, out = init(dir)
      assert_equal 0, code, out
      assert_match(/^updated +AGENTS\.md/, out)
      assert_match(/^updated +CLAUDE\.md/, out)
      agents = File.read(File.join(dir, "AGENTS.md"))
      assert agents.start_with?("# Ours\nKeep this.\n")
      assert_equal 1, agents.scan(SoftFoundry::AgentFiles::BEGIN_MARKER).size
      claude = File.read(File.join(dir, "CLAUDE.md"))
      assert claude.start_with?("Custom Claude notes\n")
      _, out = init(dir)
      assert_match(/^skipped +AGENTS\.md/, out)
      assert_match(/^skipped +CLAUDE\.md/, out)
      assert_equal 1, File.read(File.join(dir, "CLAUDE.md")).scan(SoftFoundry::AgentFiles::BEGIN_MARKER).size
    end
  end

  def test_user_edited_rule_is_conflict_then_force_overwrites # AC-006, AC-007
    with_target_repo do |dir|
      init(dir)
      commit_all(dir)
      File.write(File.join(dir, ".ai/rules/general.md"), "hardened\n")
      commit_all(dir, "harden")
      code, out = init(dir)
      assert_equal 3, code
      assert_match(/^conflict +\.ai\/rules\/general\.md/, out)
      assert_equal "hardened\n", File.read(File.join(dir, ".ai/rules/general.md"))
      code, out = init(dir, "--force")
      assert_equal 0, code, out
      assert_match(/^forced +\.ai\/rules\/general\.md/, out)
      canonical = File.binread(File.join(REPO_ROOT, ".ai/rules/general.md"))
      assert_equal canonical, File.binread(File.join(dir, ".ai/rules/general.md"))
      assert manifest(dir).owned?(".ai/rules/general.md", canonical)
    end
  end

  def test_preexisting_ai_without_manifest # AC-008
    with_target_repo do |dir|
      FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), dir)
      FileUtils.rm_f(File.join(dir, ".ai/manifest.yml"))
      File.write(File.join(dir, ".ai/rules/ruby.md"), "different\n")
      commit_all(dir)
      code, out = init(dir)
      assert_equal 3, code
      assert_match(/^skipped +\.ai\/workflow\.yml +\(identical\)/, out)
      assert_match(/^conflict +\.ai\/rules\/ruby\.md +\(not in manifest\)/, out)
      m = manifest(dir)
      assert m.include?(".ai/workflow.yml")
      refute m.include?(".ai/rules/ruby.md")
    end
  end

  def test_gitignore_already_effective_is_skipped # AC-009
    with_target_repo do |dir|
      File.write(File.join(dir, ".gitignore"), "node_modules\n.soft-foundry/\n")
      before = File.read(File.join(dir, ".gitignore"))
      _, out = init(dir)
      assert_match(/^skipped +\.gitignore/, out)
      assert_equal before, File.read(File.join(dir, ".gitignore"))
    end
  end

  def test_docs_user_not_created_when_docs_exists_without_user # AC-011
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, "docs")); File.write(File.join(dir, "docs/index.md"), "x")
      _, out = init(dir)
      refute File.exist?(File.join(dir, "docs/user"))
      assert_match(/^skipped +docs\/user\/README\.md +\(docs\/ exists without docs\/user\/\)/, out)
    end
  end

  def test_dry_run_matches_real_report_and_writes_nothing # AC-012
    with_target_repo do |dir|
      code, dry = init(dir, "--dry-run")
      assert_equal 0, code
      refute File.exist?(File.join(dir, ".ai"))
      refute File.exist?(File.join(dir, ".ai/manifest.yml"))
      _, real = init(dir)
      lines = ->(o) { o.lines.grep(/^(created|updated|skipped|conflict|forced) /) }
      assert_equal lines.(dry), lines.(real)
    end
  end

  def test_missing_packaged_workflow_is_internal_error_exit_4_with_upstream_guidance # AC-013, MIT-012
    with_target_repo do |dir|
      Dir.mktmpdir do |src|
        FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), src); FileUtils.cp(File.join(REPO_ROOT, "AGENTS.md"), src)
        FileUtils.mkdir_p(File.join(src, "changes")); FileUtils.mkdir_p(File.join(src, "docs/user"))
        File.write(File.join(src, "changes/README.md"), "x"); File.write(File.join(src, "docs/user/README.md"), "x")
        File.delete(File.join(src, ".ai/workflow.yml"))
        code, out = init(dir, env: { "OPENAI_API_KEY" => "sk-supersecret" }, src: SoftFoundry::Installer::Source.new(src))
        assert_equal 4, code
        assert_includes out, "defect in Soft Foundry"
        assert_includes out, ".ai/workflow.yml"
        assert_includes out, "github.com/jmscholen/soft_foundry"
        assert_includes out, "gh repo fork"
        refute_includes out, "sk-supersecret"
        refute_includes out.lines.grep(/^\s/).join, dir
        refute File.exist?(File.join(dir, ".ai"))
      end
    end
  end

  def test_symlinked_ai_outside_root_is_refused # AC-014
    with_target_repo do |dir|
      Dir.mktmpdir do |outside|
        File.symlink(outside, File.join(dir, ".ai"))
        code, out = init(dir)
        assert_equal 1, code
        assert_includes out, "symlink"
        assert_empty Dir.children(outside)
      end
    end
  end

  def test_init_runs_onboarding_and_provider_errors_do_not_fail # AC-015
    with_target_repo do |dir|
      out = StringIO.new
      code = nil
      with_env("OPENAI_API_KEY" => nil, "ANTHROPIC_API_KEY" => nil, "XAI_API_KEY" => nil) do
        code = SoftFoundry::CLI.new(["init"], out: out, err: out, root: dir, source: source).run
      end
      assert_equal 0, code, out.string
      assert_includes out.string, "not configured"
      assert File.exist?(File.join(dir, ".soft-foundry/runtime.yml"))
      assert_equal "", sh(dir, "git", "status", "--porcelain", "--ignored=no", ".soft-foundry")
    end
  end

  def test_root_must_be_toplevel # MIT-008
    with_target_repo do |dir|
      code, out = init(dir, "--root", File.join(dir, "lib"))
      assert_equal 1, code
      assert_includes out, "top-level"
      refute File.exist?(File.join(dir, ".ai"))
    end
  end

  def test_corrupt_manifest_is_target_error
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ai")); File.write(File.join(dir, ".ai/manifest.yml"), "version: 1\nfiles: &a {}\nb: *a\n")
      code, out = init(dir)
      assert_equal 1, code
      assert_includes out, "manifest.yml"
    end
  end

  def test_gemspec_declares_ruby_32_and_packages_scaffolding # AC-017
    spec = Gem::Specification.load(File.join(REPO_ROOT, "soft_foundry.gemspec"))
    assert spec.required_ruby_version.satisfied_by?(Gem::Version.new("3.2.0"))
    refute spec.required_ruby_version.satisfied_by?(Gem::Version.new("3.1.9"))
    %w[changes/README.md docs/user/README.md .ai/templates/repository.yml].each { |f| assert_includes spec.files, f }
  end
end

class CLIInitRemediationTest < Minitest::Test
  include FoundryFixture

  def test_root_without_value_is_a_usage_error_not_an_internal_failure # EVAL-F-001
    with_target_repo do |dir|
      code, out = init(dir, "--root")
      assert_equal 1, code
      assert_includes out, "--root requires a value"
      refute_includes out, "defect in Soft Foundry"
      refute File.exist?(File.join(dir, ".ai"))
    end
  end

  def test_conflict_report_names_paths_and_next_step # EVAL-F-003, EVAL-F-004
    with_target_repo do |dir|
      init(dir)
      commit_all(dir)
      File.write(File.join(dir, ".ai/rules/general.md"), "hardened\n")
      commit_all(dir, "harden")
      code, out = init(dir)
      assert_equal 3, code
      assert_match(/^conflicts: \.ai\/rules\/general\.md$/, out)
      assert_match(/^next: .*--force/, out)
    end
  end
end

class CLIInitAttackRemediationTest < Minitest::Test
  include FoundryFixture

  def test_regular_file_at_soft_foundry_is_target_side # ATTACK-015
    with_target_repo do |dir|
      File.write(File.join(dir, ".soft-foundry"), "x")
      code, out = init(dir)
      assert_equal 1, code, out
      refute_includes out, "defect in Soft Foundry"
    end
  end

  def test_invalid_user_yaml_under_ai_is_target_side # ATTACK-015
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ai/profiles")); File.write(File.join(dir, ".ai/profiles/mine.yml"), "not: [valid")
      code, out = init(dir)
      refute_equal 4, code, out
      refute_includes out, "defect in Soft Foundry"
      assert_includes out, "check: failed"
    end
  end

  def test_diagnostic_hides_resolved_root_when_cwd_is_elsewhere # ATTACK-015
    with_target_repo do |dir|
      Dir.mktmpdir do |cwd|
        Dir.mktmpdir do |src|
          FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), src); FileUtils.cp(File.join(REPO_ROOT, "AGENTS.md"), src)
          FileUtils.mkdir_p(File.join(src, "changes")); FileUtils.mkdir_p(File.join(src, "docs/user"))
          File.write(File.join(src, "changes/README.md"), "x"); File.write(File.join(src, "docs/user/README.md"), "x")
          File.delete(File.join(src, ".ai/workflow.yml"))
          out = StringIO.new
          code = SoftFoundry::CLI.new(["init", "--no-onboard", "--root", dir], out: out, err: out, root: cwd, source: SoftFoundry::Installer::Source.new(src)).run
          assert_equal 4, code
          refute_includes out.string.lines.grep(/^\s/).join, dir
        end
      end
    end
  end

  def test_filesystem_root_is_refused
    code, out = init("/", "--allow-non-git")
    assert_equal 1, code
    assert_includes out, "filesystem root"
  end
end

class CLIBudgetTest < Minitest::Test
  include FoundryFixture

  def test_status_and_record_round_trip
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "bud1", "--title", "x")
      code, out = cli(dir, "budget", "status", "--change", "bud1")
      assert_equal 0, code, out
      assert_includes out, "unknown"

      code, out = cli(dir, "budget", "record", "--change", "bud1", "--phase", "00-intake", "--provider", "anthropic", "--model", "claude-sonnet-5", "--tokens-in", "1000", "--tokens-out", "200", "--usd", "0.10")
      assert_equal 0, code, out
      assert_includes out, "recorded:"

      code, out = cli(dir, "budget", "status", "--change", "bud1")
      assert_equal 0, code, out
      assert_includes out, "$0.10"
    end
  end

  def test_status_reports_over_cap_with_exit_2
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "bud2", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "bud2", control_plane: SoftFoundry::ControlPlane.new(dir))
      d = YAML.safe_load_file(File.join(record.dir, "metadata.yml"), permitted_classes: [Time, Date]); d["risk"] = "low"; File.write(File.join(record.dir, "metadata.yml"), YAML.dump(d))
      cli(dir, "budget", "record", "--change", "bud2", "--phase", "05-implementation", "--provider", "anthropic", "--model", "m", "--tokens-in", "1", "--tokens-out", "1", "--usd", "20.00")
      code, out = cli(dir, "budget", "status", "--change", "bud2")
      assert_equal 2, code, out
      assert_includes out, "OVER CAP"
    end
  end
end

class CLIMaturityTest < Minitest::Test
  include FoundryFixture

  def test_init_scans_maturity_by_default
    with_target_repo do |dir|
      code, out = init(dir)
      assert_equal 0, code, out
      assert_includes out, "maturity: scanned"
      data = YAML.safe_load_file(File.join(dir, ".ai/repository.yml"))
      assert data.dig("repository", "assessed")
    end
  end

  def test_second_init_skips_already_assessed_maturity
    with_target_repo do |dir|
      init(dir)
      _, out = init(dir)
      assert_includes out, "already assessed"
      refute_includes out, "maturity: scanned"
    end
  end

  def test_reassess_forces_a_fresh_scan
    with_target_repo do |dir|
      init(dir)
      _, out = init(dir, "--reassess")
      assert_includes out, "maturity: scanned"
    end
  end

  def test_maturity_off_skips_entirely
    with_target_repo do |dir|
      _, out = init(dir, "--maturity", "off")
      refute_includes out, "maturity:"
      data = YAML.safe_load_file(File.join(dir, ".ai/repository.yml"))
      refute data.dig("repository", "assessed")
    end
  end

  def test_unknown_maturity_mode_is_a_usage_error
    with_target_repo do |dir|
      code, out = init(dir, "--maturity", "bogus")
      assert_equal 1, code
      assert_includes out, "unknown --maturity mode"
      refute File.exist?(File.join(dir, ".ai"))
    end
  end

  def test_onboard_alone_also_scans_maturity
    with_target_repo do |dir|
      init(dir, "--maturity", "off")
      out = StringIO.new
      code = with_env("OPENAI_API_KEY" => nil, "ANTHROPIC_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil) do
        SoftFoundry::CLI.new(["onboard"], out: out, err: out, root: dir, source: source).run
      end
      assert_equal 0, code, out.string
      assert_includes out.string, "maturity: scanned"
    end
  end
end

class CLIClosedChangeCiTest < Minitest::Test
  include FoundryFixture

  def test_ci_skips_a_closed_change
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "old1", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "old1", control_plane: SoftFoundry::ControlPlane.new(dir))
      m = YAML.safe_load_file(record.dir + "/metadata.yml", permitted_classes: [Time, Date])
      m["status"] = "closed"
      File.write(record.dir + "/metadata.yml", YAML.dump(m))
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      assert_includes out, "old1 (closed, skipped)"
    end
  end
end
