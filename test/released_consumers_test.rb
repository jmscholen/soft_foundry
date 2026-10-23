# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Every consumer that special-cases `closed` makes a defined choice for
# `released` (REQ-021), and phase reopens and releases are visible in the
# snapshot (REQ-026).
class ReleasedConsumersTest < Minitest::Test
  include FinishedFixture

  def released_record(dir, record, items: %w[A-1 B-2])
    record.update_metadata do |m|
      m["status"] = "released"
      m["release"] = { "at" => "2026-10-24T09:00:00Z", "commit" => head(dir),
                       "items" => items.map { |id| { "id" => id, "description" => "confirm #{id}" } } }
    end
  end

  def snapshot_for(dir)
    plane = SoftFoundry::ControlPlane.new(dir)
    git = SoftFoundry::Git.new(dir)
    SoftFoundry::Snapshot.new(dir, plane: plane, git: git, index: SoftFoundry::ChangeIndex.new(dir, plane: plane, git: git))
  end

  # --- scope ------------------------------------------------------------------------

  def test_a_released_record_claims_no_scope
    with_finished_record do |dir, record|
      record.update_metadata { |m| m["scope"] = %w[lib/**] }
      commit_all(dir, "scope")
      other = SoftFoundry::ChangeRecord.create(dir, "other", control_plane: SoftFoundry::ControlPlane.new(dir), scope: %w[test/**])
      scope = SoftFoundry::Scope.new(other, git: SoftFoundry::Git.new(dir))
      assert_equal ["c1"], scope.claimants("lib/app.rb")
      released_record(dir, record)
      assert_equal [], scope.claimants("lib/app.rb")
    end
  end

  def test_check_does_not_lint_the_scope_of_a_released_record
    with_finished_record do |dir, record|
      record.update_metadata { |m| m["scope"] = "not-a-list" }
      commit_all(dir, "bad scope")
      released_record(dir, record)
      commit_all(dir, "released")
      code, out = cli(dir, "check")
      assert_equal 0, code, out
    end
  end

  # --- snapshot, board, overview -----------------------------------------------------

  def test_the_board_shows_a_released_record_as_released_with_its_open_items_and_does_not_gate_it
    with_finished_record do |dir, record|
      released_record(dir, record)
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed: evidence is stale now")
      row = snapshot_for(dir).board["changes"].find { |r| r["slug"] == "c1" }
      assert_equal "released", row["status"]
      assert_equal true, row["released"]
      assert_equal false, row["closed"]
      assert_equal 2, row["open_items"]
      assert_equal false, row["evaluated"], "a released record is not re-gated"
      assert_equal false, row["stale"]
    end
  end

  def test_the_overview_counts_released_records_and_keeps_them_listed
    with_finished_record do |dir, record|
      released_record(dir, record)
      overview = snapshot_for(dir).overview
      assert_equal 1, overview["released"]
      assert_equal 0, overview["closed"]
      listed = overview["changes"].find { |c| c["slug"] == "c1" }
      assert_equal "released", listed["status"]
      assert_equal 2, listed["open_items"]
    end
  end

  def test_a_closed_record_is_unchanged_in_the_overview
    with_finished_record do |dir, record|
      record.update_metadata { |m| m["status"] = "closed" }
      overview = snapshot_for(dir).overview
      assert_equal 1, overview["closed"]
      assert_equal 0, overview["released"]
    end
  end

  def test_the_change_view_carries_the_release_block_and_phase_reopenings
    with_finished_record do |dir, record|
      released_record(dir, record)
      change = snapshot_for(dir).change("c1")
      assert_equal true, change["released"]
      assert_equal %w[A-1 B-2], change["release"]["items"].map { |i| i["id"] }
      assert_equal 2, change["open_items"]
    end
  end

  def test_the_timeline_shows_phase_reopens_distinctly_and_labels_automatic_ones
    with_finished_record do |dir, record|
      record.update_metadata do |m|
        m["reopenings"] = [{ "at" => "2026-10-20T10:00:00Z", "reason" => "reshape" }]
        m["phase_reopenings"] = [
          { "at" => "2026-10-21T10:00:00Z", "phase" => "attack", "reset" => %w[attack review judge], "from_commit" => "abcdef1234567", "reason" => "fixture changed", "source" => "manual", "previous" => {} },
          { "at" => "2026-10-22T10:00:00Z", "phase" => "verify", "reset" => %w[verify], "from_commit" => "1234567abcdef", "reason" => "gate check failed", "source" => "auto", "previous" => {} }
        ]
        m["status"] = "released"
        m["release"] = { "at" => "2026-10-23T10:00:00Z", "commit" => "c", "items" => [
          { "id" => "A-1", "description" => "a", "discharged_at" => "2026-10-24T10:00:00Z", "discharge_note" => "seen" }, { "id" => "B-2", "description" => "b" }
        ] }
      end
      events = snapshot_for(dir).change("c1")["timeline"]
      by_kind = events.group_by { |e| e["kind"] }
      assert_equal 1, by_kind["reopened"].size
      assert_includes by_kind["reopened"].first["label"], "reopened for exploring"
      manual, auto = by_kind["phase_reopened"]
      assert_includes manual["label"], "phase attack reopened (manual)"
      assert_includes manual["label"], "reset attack, review, judge"
      assert_includes manual["label"], "abcdef1"
      assert_includes manual["label"], "fixture changed"
      assert_includes auto["label"], "phase verify reopened (automatic)"
      assert_includes by_kind["released"].first["label"], "released with 2 item(s)"
      assert_includes by_kind["discharged"].first["label"], "discharged A-1"
      assert_includes by_kind["discharged"].first["label"], "seen"
    end
  end

  # --- change status and ps ----------------------------------------------------------------

  def test_change_status_lists_a_released_records_open_items
    with_finished_record do |dir, record|
      released_record(dir, record)
      _, out = cli(dir, "change", "status", "c1")
      assert_match(/status: released/, out)
      assert_includes out, "released: c1: 2 open item(s): A-1, B-2"
    end
  end

  def test_the_ps_command_table_names_the_new_commands
    sub = SoftFoundry::Processes::SUBCOMMANDS
    assert_includes sub["phase"], "reopen"
    assert_includes sub["change"], "release"
    assert_includes sub["change"], "discharge"
  end

  # --- refusals -----------------------------------------------------------------------------

  def test_learn_promote_treats_released_as_finished
    with_finished_record do |dir, record|
      released_record(dir, record)
      code, out, err = run_cli(dir, "learn", "promote")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/released/, out + err)
    end
  end

  def test_change_reopen_refuses_a_released_record
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/it1")
      cli(dir, "change", "new", "it1", "--track", "iterative")
      record = SoftFoundry::ChangeRecord.new(dir, "it1", control_plane: SoftFoundry::ControlPlane.new(dir))
      record.update_metadata { |m| m["status"] = "released" }
      code, out, err = run_cli(dir, "change", "reopen", "it1", "--reason", "r")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/released/, out + err)
      assert_equal "released", record.metadata["status"]
    end
  end

  def test_a_released_record_cannot_be_run_reopened_or_released_again
    with_finished_record do |dir, record|
      released_record(dir, record)
      before = tree_bytes(dir)
      [%w[phase run review], ["phase", "reopen", "review", "--reason", "r"], %w[change release c1 --item X=y]].each do |args|
        code, out, err = run_cli(dir, *args)
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, args.inspect
        assert_match(/released/, out + err, args.inspect)
      end
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_the_guard_resolves_no_skill_for_a_released_record
    with_finished_record do |dir, record|
      released_record(dir, record)
      decision = SoftFoundry::Guard.new(dir, env: {}).decide("Edit", { "file_path" => "lib/app.rb" })
      assert_equal :allow, decision.outcome
      assert_includes decision.reason, "released"
    end
  end

  # --- harness evals ---------------------------------------------------------------------------

  def test_a_harness_eval_case_may_plant_a_released_status
    assert_includes SoftFoundry::HarnessEval::STATUSES, "released"
  end
end
