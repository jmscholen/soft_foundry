# frozen_string_literal: true

require_relative "test_helper"

class CLIChangeCloseTest < Minitest::Test
  include FoundryFixture

  # Creates a change record on its own branch, completes intake and
  # judgment with the given evidence (a change isn't "done" until it's
  # been judged - completing only intake would leave commit_sha_at_judgment
  # nil, and reaching for last_commit_sha there would just be checking
  # whether the branch's fork point predates main, which it always does),
  # and (optionally) merges the branch into main - the shape every test in
  # this file starts from.
  def with_merged_change(slug, evidence: nil, merge: true)
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug, "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: SoftFoundry::ControlPlane.new(dir))
      commit_all(dir, "record #{slug}")
      sha = head(dir)
      # Every required (non-optional) phase up to and including judgment,
      # so predecessor checks in the gate chain are satisfied too.
      %w[intake discover specify threat_model plan implement verify evaluate attack review judge].each do |id|
        complete_phase!(record, id, sha: sha)
      end
      File.write(record.judgment_evidence_path, YAML.dump(evidence)) if evidence
      commit_all(dir, "complete #{slug} through judgment")
      if merge
        sh(dir, "git", "checkout", "-q", "main")
        sh(dir, "git", "merge", "-q", "--no-ff", "change/#{slug}", "-m", "merge #{slug}")
      end
      yield dir, record
    end
  end

  # An early, abandoned change whose only completed phase is intake never
  # reached judgment - its intake commit is trivially an ancestor of main
  # (branches fork from main), which must not read as "this change's work
  # merged." Regression for a real false positive this check produced
  # against soft_foundry's own changes/upstream-failure-reporting.
  def test_ci_does_not_flag_an_early_abandoned_change_as_merged
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/stalled")
      cli(dir, "change", "new", "stalled", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "stalled", control_plane: SoftFoundry::ControlPlane.new(dir))
      commit_all(dir, "record stalled")
      complete_phase!(record, "intake", sha: head(dir))
      commit_all(dir, "complete intake only")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/stalled", "-m", "merge stalled up to intake")

      assert_nil record.commit_sha_at_judgment
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      refute_includes out, "merged into main"
    end
  end

  def test_ci_flags_a_merged_change_that_is_not_closed
    with_merged_change("feat1") do |dir, _record|
      code, out = cli(dir, "ci")
      assert_equal 2, code, out
      assert_includes out, "merged into main but status is"
      assert_includes out, "soft-foundry change close feat1"
    end
  end

  def test_ci_does_not_flag_an_unmerged_change
    with_merged_change("feat2", merge: false) do |dir, _record|
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      refute_includes out, "merged into main"
    end
  end

  def test_close_refuses_when_not_yet_merged
    with_merged_change("feat3", merge: false) do |dir, _record|
      code, out = cli(dir, "change", "close", "feat3")
      assert_equal 1, code
      assert_includes out, "not reachable from main"
    end
  end

  def test_close_force_closes_an_unmerged_change_anyway
    with_merged_change("feat4", merge: false) do |dir, record|
      code, out = cli(dir, "change", "close", "feat4", "--force")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
    end
  end

  def test_close_succeeds_once_merged_with_nothing_undischarged
    with_merged_change("feat5") do |dir, record|
      code, out = cli(dir, "change", "close", "feat5")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
      assert_equal "done", record.metadata["current_phase"]
    end
  end

  def test_close_refuses_an_undischarged_item_with_no_confirmation
    evidence = {"undischarged" => [{"id" => "AC-060", "description" => "observed on production"}]}
    with_merged_change("feat6", evidence: evidence) do |dir, record|
      code, out = cli(dir, "change", "close", "feat6")
      assert_equal 1, code
      assert_includes out, "AC-060"
      refute_equal "closed", record.metadata["status"]
    end
  end

  def test_close_succeeds_with_an_explicit_confirm_flag
    evidence = {"undischarged" => [{"id" => "AC-060", "description" => "observed on production"}]}
    with_merged_change("feat7", evidence: evidence) do |dir, record|
      code, out = cli(dir, "change", "close", "feat7", "--confirm", "AC-060")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
      assert_empty record.undischarged_acceptance
      discharged = record.judgment_evidence["discharged"]
      assert_equal "explicit --confirm", discharged.first["discharged_by"]
    end
  end

  def test_close_succeeds_via_a_confirmed_pr_comment
    evidence = {"undischarged" => [{"id" => "AC-060", "description" => "observed on production"}]}
    with_merged_change("feat8", evidence: evidence) do |dir, record|
      fetcher = ->(_pr) { [["CONFIRMED: AC-060"], nil] }
      out = StringIO.new
      code = SoftFoundry::CLI.new(["change", "close", "feat8", "--pr", "9"], out: out, err: out, root: dir,
                                   pr_discharge: SoftFoundry::PrDischarge.new(dir, fetcher: fetcher)).run
      assert_equal 0, code, out.string
      assert_equal "closed", record.metadata["status"]
      assert_equal "PR #9 comment", record.judgment_evidence["discharged"].first["discharged_by"]
    end
  end

  def test_close_is_idempotent_once_already_closed
    with_merged_change("feat9") do |dir, record|
      cli(dir, "change", "close", "feat9")
      code, out = cli(dir, "change", "close", "feat9")
      assert_equal 0, code, out
      assert_includes out, "already closed"
    end
  end

  def test_request_discharge_posts_a_comment_naming_each_undischarged_item
    evidence = {"undischarged" => [{"id" => "AC-060", "description" => "observed on production"}]}
    with_merged_change("feat10", evidence: evidence) do |dir, _record|
      posted = nil
      poster = ->(pr, body) { posted = [pr, body] }
      out = StringIO.new
      code = SoftFoundry::CLI.new(["change", "request-discharge", "feat10", "--pr", "3"], out: out, err: out, root: dir,
                                   pr_discharge: SoftFoundry::PrDischarge.new(dir, poster: poster)).run
      assert_equal 0, code, out.string
      pr, body = posted
      assert_equal "3", pr
      assert_includes body, "AC-060"
    end
  end

  def test_request_discharge_is_a_noop_with_nothing_undischarged
    with_merged_change("feat11") do |dir, _record|
      code, out = cli(dir, "change", "request-discharge", "feat11", "--pr", "3")
      assert_equal 0, code, out
      assert_includes out, "nothing undischarged"
    end
  end
end
