# frozen_string_literal: true

require_relative "test_helper"

# A record's evidence goes stale relative to its own branch. A change
# stacked on another change's branch does not make the earlier record
# stale; the earlier record's branch itself, or a worktree edit on it,
# does. Once the branch is gone, HEAD is the measure again.
class StackedBranchTest < Minitest::Test
  include FoundryFixture

  # change/a with verification complete at its HEAD, then change/b stacked
  # on it with a code commit of its own.
  def with_stack
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      sh(dir, "git", "checkout", "-qb", "change/a")
      cli(dir, "change", "new", "a")
      a = SoftFoundry::ChangeRecord.new(dir, "a", control_plane: plane)
      commit_all(dir, "record a")
      plane.phases.take(7).each { |p| complete_phase!(a, p.id, sha: head(dir)) } # intake..verify
      commit_all(dir, "a verified")

      sh(dir, "git", "checkout", "-qb", "change/b")
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "b changes code")
      yield dir, a, SoftFoundry::Gate.new(a, git: SoftFoundry::Git.new(dir))
    end
  end

  def current(gate) = gate.evaluate("verify").checks.find { |c| c.name == "evidence current" }

  def test_a_stacked_branch_does_not_stale_the_earlier_record
    with_stack do |_dir, _a, gate|
      check = current(gate)
      assert_equal :pass, check.outcome, check.detail
      assert_includes check.detail, "on branch change/a"
    end
  end

  def test_the_record_branch_itself_is_measured_by_its_worktree
    with_stack do |dir, _a, gate|
      sh(dir, "git", "checkout", "-q", "change/a")
      assert_equal :pass, current(gate).outcome
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      check = current(gate)
      assert_equal :fail, check.outcome
      refute_includes check.detail, "on branch", "on its own branch the worktree is the measure"
    end
  end

  def test_a_commit_on_the_record_branch_is_seen_from_the_stacked_branch
    with_stack do |dir, _a, gate|
      sh(dir, "git", "checkout", "-q", "change/a")
      File.write(File.join(dir, "lib", "app.rb"), "puts 4\n")
      commit_all(dir, "a changes code after verifying")
      sh(dir, "git", "checkout", "-q", "change/b")
      check = current(gate)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "on branch change/a"
    end
  end

  def test_once_the_record_branch_is_gone_head_is_the_measure
    with_stack do |dir, _a, gate|
      sh(dir, "git", "branch", "-D", "change/a")
      assert_equal :fail, current(gate).outcome, "b's code commit is after a's evidence and there is no branch to measure on"
    end
  end

  def test_ci_on_a_stacked_branch_passes_with_the_earlier_record_open
    with_stack do |dir, _a, _gate|
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      assert_includes out, "no code changes since"
      assert_includes out, "on branch change/a"
    end
  end
end
