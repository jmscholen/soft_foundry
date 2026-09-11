# frozen_string_literal: true

require_relative "test_helper"

class GitTest < Minitest::Test
  include FoundryFixture

  def test_default_branch_falls_back_to_local_main_without_a_remote
    with_target_repo do |dir|
      git = SoftFoundry::Git.new(dir)
      assert_equal "main", git.default_branch
    end
  end

  def test_default_branch_prefers_origin_head_when_present
    with_target_repo do |dir|
      sh(dir, "git", "branch", "-m", "main", "trunk")
      sh(dir, "git", "remote", "add", "origin", dir)
      sh(dir, "git", "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/trunk")
      git = SoftFoundry::Git.new(dir)
      assert_equal "trunk", git.default_branch
    end
  end

  def test_ancestor_is_true_once_a_branch_merges_and_false_before
    with_target_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "feature")
      File.write(File.join(dir, "lib", "feature.rb"), "puts 2\n")
      commit_all(dir, "feature work")
      feature_sha = head(dir)

      sh(dir, "git", "checkout", "-q", "main")
      git = SoftFoundry::Git.new(dir)
      refute git.ancestor?(feature_sha, "main"), "unmerged work must not read as merged"

      sh(dir, "git", "merge", "-q", "--no-ff", "feature", "-m", "merge feature")
      assert git.ancestor?(feature_sha, "main")
    end
  end

  def test_ancestor_is_false_for_a_malformed_sha_or_missing_ref
    with_target_repo do |dir|
      git = SoftFoundry::Git.new(dir)
      refute git.ancestor?("not-a-sha", "main")
      refute git.ancestor?(head(dir), "no-such-branch")
    end
  end
end
