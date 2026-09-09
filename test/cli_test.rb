# frozen_string_literal: true

require_relative "test_helper"

class CLITest < Minitest::Test
  include FoundryFixture

  def test_check_change_new_status_gate_and_ci
    with_fixture_repo do |dir|
      code, out = cli(dir, "check")
      assert_equal 0, code, out
      assert_includes out, "no errors"

      code, out = cli(dir, "change", "new", "c1", "--title", "First change", "--branch", "change/c1")
      assert_equal 0, code, out
      assert File.exist?(File.join(dir, "changes/c1/00-intake/handoff.yml"))

      code, out = cli(dir, "change", "status", "c1")
      assert_equal 0, code, out
      assert_includes out, "First change"

      code, out = cli(dir, "gate", "intake", "--change", "c1")
      assert_equal 0, code, out
      assert_includes out, "SKIP"

      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      assert_includes out, "ci passed"
    end
  end

  def test_gate_resolves_change_from_branch_name
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      cli(dir, "change", "new", "c2")
      code, out = cli(dir, "gate", "all")
      assert_equal 0, code, out
    end
  end

  def test_ci_fails_on_inconsistent_record
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c3")
      record = SoftFoundry::ChangeRecord.new(dir, "c3", control_plane: SoftFoundry::ControlPlane.new(dir))
      complete_phase!(record, "intake", sha: head(dir), fill: false)
      code, out = cli(dir, "ci")
      assert_equal 2, code
      assert_includes out, "ci failed"
    end
  end

  def test_hooks_install_and_doctor
    with_fixture_repo do |dir|
      code, out = cli(dir, "hooks", "install")
      assert_equal 0, code, out
      assert File.executable?(File.join(dir, ".git/hooks/pre-commit"))
      code, out = cli(dir, "doctor")
      assert_includes out, "✓ control plane check"
      assert_includes out, "✓ pre-commit hook"
      assert_equal 2, code, "local runtime is absent, doctor should report it"
    end
  end
end
