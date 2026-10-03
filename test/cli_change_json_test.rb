# frozen_string_literal: true

require "json"
require_relative "test_helper"

class CLIChangeJsonTest < Minitest::Test
  include FoundryFixture

  def with_change
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1", "--title", "First change")
      commit_all(dir, "record c1")
      yield dir, SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
    end
  end

  def test_change_list_json_is_the_board
    with_change do |dir, _record|
      code, out = cli(dir, "change", "list", "--json")
      assert_equal 0, code, out
      board = JSON.parse(out)
      assert_equal 1, board["version"]
      assert_equal ["c1"], board["changes"].map { |c| c["slug"] }
      assert_equal 16, board["changes"].first["cells"].size
    end
  end

  def test_change_list_without_json_still_prints_slugs
    with_change do |dir, _record|
      code, out = cli(dir, "change", "list")
      assert_equal 0, code
      assert_equal "c1\n", out
    end
  end

  def test_change_status_json_for_a_named_slug
    with_change do |dir, record|
      complete_phase!(record, "intake", sha: head(dir))
      code, out = cli(dir, "change", "status", "c1", "--json")
      assert_equal 0, code, out
      change = JSON.parse(out)
      assert_equal "c1", change["slug"]
      assert_equal "pass", change["gates"].first["state"]
    end
  end

  def test_change_status_json_uses_the_branch_when_no_slug_is_given
    with_change do |dir, _record|
      code, out = cli(dir, "change", "status", "--json")
      assert_equal 0, code, out
      assert_equal "c1", JSON.parse(out)["slug"]
    end
  end

  # --json changes the format only: a failing gate is still exit 2.
  def test_change_status_json_keeps_the_failing_exit_code
    with_change do |dir, record|
      complete_phase!(record, "specify", sha: head(dir))
      code, out = cli(dir, "change", "status", "c1", "--json")
      assert_equal 2, code
      assert JSON.parse(out)["failed"]
      text_code, = cli(dir, "change", "status", "c1")
      assert_equal 2, text_code
    end
  end

  def test_change_status_json_for_an_unknown_slug_is_a_target_error
    with_change do |dir, _record|
      code, out = cli(dir, "change", "status", "nope", "--json")
      assert_equal 1, code
      assert_includes out, "no change record at changes/nope"
    end
  end

  def test_status_text_still_prints_the_track_line
    with_change do |dir, _record|
      _, out = cli(dir, "change", "status", "c1")
      assert_includes out, "  track: gated\n"
      cli(dir, "change", "new", "c2", "--title", "x", "--track", "iterative")
      _, explored = cli(dir, "change", "status", "c2")
      assert_includes explored, "track: iterative (exploring; 0 iterations recorded; run `soft-foundry change vet` when the person has accepted the feature)"
    end
  end

  def test_help_names_the_json_flag
    with_fixture_repo do |dir|
      _, out = cli(dir)
      assert_includes out, "change status [slug] [--json]"
      assert_includes out, "change list [--json]"
    end
  end
end
