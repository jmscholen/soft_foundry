# frozen_string_literal: true

require_relative "test_helper"

class InstallerSourceTest < Minitest::Test
  include FoundryFixture

  def test_packaged_set_has_the_two_exceptions_and_scaffolding
    paths = source.paths
    assert_includes paths, ".ai/workflow.yml"
    assert_includes paths, ".ai/repository.yml"
    assert_includes paths, ".ai/harness-evals/README.md"
    assert_includes paths, "changes/README.md"
    assert_includes paths, "docs/user/README.md"
    refute_includes paths, ".ai/manifest.yml"
    assert_empty paths.select { |p| p.start_with?(".ai/harness-evals/") && p != ".ai/harness-evals/README.md" }
    template = File.binread(File.join(REPO_ROOT, ".ai/templates/repository.yml"))
    assert_equal template, source.entries.find { |e| e.path == ".ai/repository.yml" }.bytes
    assert_includes YAML.safe_load(template).dig("repository", "assessed").to_s, "false"
  end

  def test_agents_interior_comes_from_between_markers
    interior = source.agents_interior
    refute_includes interior, "soft-foundry:begin"
    assert_includes interior, "Read `.ai/README.md`"
  end

  def test_missing_required_file_is_internal_error
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), dir)
      FileUtils.cp(File.join(REPO_ROOT, "AGENTS.md"), dir)
      FileUtils.mkdir_p(File.join(dir, "changes")); FileUtils.mkdir_p(File.join(dir, "docs/user"))
      File.write(File.join(dir, "changes/README.md"), "x"); File.write(File.join(dir, "docs/user/README.md"), "x")
      File.delete(File.join(dir, ".ai/workflow.yml"))
      e = assert_raises(SoftFoundry::InternalError) { SoftFoundry::Installer::Source.new(dir).entries }
      assert_includes e.message, ".ai/workflow.yml"
    end
  end

  def test_symlinked_packaged_entry_is_internal_error
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), dir)
      FileUtils.cp(File.join(REPO_ROOT, "AGENTS.md"), dir)
      FileUtils.mkdir_p(File.join(dir, "changes")); FileUtils.mkdir_p(File.join(dir, "docs/user"))
      File.write(File.join(dir, "changes/README.md"), "x"); File.write(File.join(dir, "docs/user/README.md"), "x")
      File.symlink("/etc/hosts", File.join(dir, ".ai/rules/evil.md"))
      assert_raises(SoftFoundry::InternalError) { SoftFoundry::Installer::Source.new(dir).entries }
    end
  end
end
