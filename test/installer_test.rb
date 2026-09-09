# frozen_string_literal: true

require_relative "test_helper"

class InstallerTest < Minitest::Test
  include FoundryFixture

  def installer(dir, **opts) = SoftFoundry::Installer.new(dir, source: source, **opts)
  def action(plan, path) = plan.actions.find { |a| a.path == path }

  def test_force_with_allow_non_git_is_refused
    with_target_repo { |dir| assert_raises(SoftFoundry::TargetError) { installer(dir, force: true, allow_non_git: true).plan } }
  end

  def test_uncommitted_modification_is_conflict_even_under_force
    with_target_repo do |dir|
      installer(dir).apply(installer(dir).plan)
      commit_all(dir)
      File.write(File.join(dir, ".ai/rules/general.md"), "hardened\n")
      a = action(installer(dir, force: true).plan, ".ai/rules/general.md")
      assert_equal "conflict", a.status
      assert_equal "uncommitted modifications", a.reason
    end
  end

  def test_forged_manifest_cannot_claim_an_uncommitted_user_file
    with_target_repo do |dir|
      installer(dir).apply(installer(dir).plan)
      commit_all(dir)
      File.write(File.join(dir, ".ai/rules/general.md"), "hardened\n")
      m = SoftFoundry::Manifest.load(dir)
      m.add(".ai/rules/general.md", "hardened\n")
      File.write(File.join(dir, ".ai/manifest.yml"), m.to_yaml)
      assert_equal "conflict", action(installer(dir).plan, ".ai/rules/general.md").status
    end
  end

  def test_manifest_entry_outside_packaged_set_is_warned_and_ignored
    with_target_repo do |dir|
      installer(dir).apply(installer(dir).plan)
      m = SoftFoundry::Manifest.load(dir)
      m.add(".ai/private/notes.md", "x")
      File.write(File.join(dir, ".ai/manifest.yml"), m.to_yaml)
      FileUtils.mkdir_p(File.join(dir, ".ai/private")); File.write(File.join(dir, ".ai/private/notes.md"), "x")
      plan = installer(dir).plan
      assert plan.warnings.any? { |w| w.include?(".ai/private/notes.md") }
      refute plan.manifest.include?(".ai/private/notes.md")
      installer(dir).apply(plan)
      assert File.exist?(File.join(dir, ".ai/private/notes.md")), "init never deletes"
    end
  end

  def test_force_never_touches_pointer_files_state_or_gitignore
    with_target_repo do |dir|
      File.write(File.join(dir, "AGENTS.md"), "# x\n#{SoftFoundry::AgentFiles::BEGIN_MARKER}\n")
      FileUtils.mkdir_p(File.join(dir, ".ai")); File.write(File.join(dir, ".ai/repository.yml"), "mine: true\n")
      File.write(File.join(dir, ".gitignore"), ".soft-foundry/\n!.soft-foundry/\n")
      commit_all(dir)
      plan = installer(dir, force: true).plan
      assert_equal "conflict", action(plan, "AGENTS.md").status
      assert_equal "skipped", action(plan, ".ai/repository.yml").status
      assert_equal "conflict", action(plan, ".gitignore").status
      installer(dir).apply(plan)
      assert_equal "mine: true\n", File.read(File.join(dir, ".ai/repository.yml"))
    end
  end

  def test_internal_symlink_and_fifo_are_refused_before_writing
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ai/elsewhere"))
      File.symlink(File.join(dir, ".ai/elsewhere"), File.join(dir, ".ai/rules"))
      e = assert_raises(SoftFoundry::TargetError) { installer(dir).plan }
      assert_includes e.message, "symlink"
      refute File.exist?(File.join(dir, ".ai/workflow.yml"))
    end
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ai"))
      File.mkfifo(File.join(dir, ".ai/workflow.yml"))
      assert_raises(SoftFoundry::TargetError) { installer(dir).plan }
    end
  end

  def test_write_failure_reports_written_files_and_leaves_no_manifest
    with_target_repo do |dir|
      calls = 0
      writer = lambda do |path, bytes|
        calls += 1
        raise Errno::ENOSPC, path if calls == 3
        FileUtils.mkdir_p(File.dirname(path)); File.binwrite(path, bytes)
      end
      inst = installer(dir, writer: writer)
      e = assert_raises(SoftFoundry::TargetError) { inst.apply(inst.plan) }
      assert_includes e.message, "files already written: "
      assert_includes e.message, "manifest not written"
      refute File.exist?(File.join(dir, ".ai/manifest.yml"))
    end
  end

  def test_concurrent_run_is_refused_by_lock
    with_target_repo do |dir|
      FileUtils.mkdir_p(File.join(dir, ".soft-foundry"))
      File.open(File.join(dir, ".soft-foundry/init.lock"), File::RDWR | File::CREAT) do |lock|
        lock.flock(File::LOCK_EX)
        inst = installer(dir)
        assert_raises(SoftFoundry::TargetError) { inst.apply(inst.plan) }
      end
    end
  end

  def test_gitignore_negation_is_conflict_and_effective_entry_is_skipped
    with_target_repo do |dir|
      File.write(File.join(dir, ".gitignore"), ".soft-foundry\n")
      assert_equal "skipped", action(installer(dir).plan, ".gitignore").status
      File.write(File.join(dir, ".gitignore"), ".soft-foundry/\n!.soft-foundry/\n")
      assert_equal "conflict", action(installer(dir).plan, ".gitignore").status
    end
  end
end
