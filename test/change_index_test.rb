# frozen_string_literal: true

require_relative "test_helper"

class ChangeIndexTest < Minitest::Test
  include FoundryFixture

  REQUIRED = %w[intake discover specify threat_model plan implement verify evaluate attack review judge learn].freeze

  def index(dir)
    SoftFoundry::ChangeIndex.new(dir, plane: SoftFoundry::ControlPlane.new(dir), git: SoftFoundry::Git.new(dir))
  end

  def test_slugs_are_sorted_and_include_nested_slugs
    with_fixture_repo do |dir|
      assert_equal [], index(dir).slugs
      cli(dir, "change", "new", "zeta", "--title", "z")
      cli(dir, "change", "new", "team/alpha", "--title", "a")
      assert_equal %w[team/alpha zeta], index(dir).slugs
    end
  end

  def test_record_returns_the_record_and_refuses_an_unknown_slug
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1", "--title", "x")
      assert_equal "c1", index(dir).record("c1").slug
      error = assert_raises(RuntimeError) { index(dir).record("nope") }
      assert_equal "no change record at changes/nope", error.message
    end
  end

  def test_merged_unclosed_is_true_only_for_a_finished_merged_record_that_is_not_closed
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1", "--title", "x")
      record = index(dir).record("c1")
      commit_all(dir, "record c1")
      sha = head(dir)
      refute index(dir).merged_unclosed?(record), "nothing is finished yet"

      REQUIRED.each { |id| complete_phase!(record, id, sha: sha) }
      commit_all(dir, "complete c1")
      refute index(dir).merged_unclosed?(record), "finished but not merged"

      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
      assert index(dir).merged_unclosed?(record)

      record.close!
      refute index(dir).merged_unclosed?(record), "closed records are settled"
    end
  end
end
