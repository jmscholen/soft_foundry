# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The released state: what release and discharge require, what they
# write, and what each refusal leaves untouched.
class ReleaseStateTest < Minitest::Test
  include FinishedFixture

  def release_for(dir, record) = SoftFoundry::Release.new(dir, plane: SoftFoundry::ControlPlane.new(dir), git: SoftFoundry::Git.new(dir), record: record)

  def release(dir, record, *items, env: {}, now: Time.utc(2026, 10, 24, 9, 0, 0)) = release_for(dir, record).release(items, env: env, now: now)

  def test_release_records_the_block_and_sets_the_status
    with_finished_record do |dir, record|
      release(dir, record, "GOLIVE-1=switch the flag on")
      meta = record.metadata
      assert_equal "released", meta["status"]
      block = meta["release"]
      assert_equal "2026-10-24T09:00:00Z", block["at"]
      assert_equal head(dir), block["commit"]
      assert_equal [{ "id" => "GOLIVE-1", "description" => "switch the flag on" }], block["items"]
      assert_predicate record, :released?
      assert_equal ["GOLIVE-1"], record.open_release_items.map { |i| i["id"] }
    end
  end

  def test_release_does_not_need_the_change_to_be_merged_and_approved_with_residual_risk_counts
    with_finished_record(outcome: "APPROVED_WITH_RESIDUAL_RISK", merge: false) do |dir, record|
      release(dir, record, "A=a")
      assert_equal "released", record.metadata["status"]
    end
  end

  def test_item_validation_refuses_and_writes_nothing
    with_finished_record do |dir, record|
      before = tree_bytes(dir)
      [[], ["A=a", "A=b"], ["lower=x"], ["-A=x"], ["A="], ["A=   "], ["A=#{'x' * 501}"], ["A=two\nlines"], ["NOEQUALS"], ["=nothing"]].each do |items|
        assert_raises(ArgumentError, items.inspect) { release(dir, record, *items) }
      end
      assert_equal before, tree_bytes(dir)
      assert_equal "in_progress", record.metadata["status"]
    end
  end

  def test_a_501_character_description_names_the_limit_and_500_is_accepted
    with_finished_record do |dir, record|
      error = assert_raises(ArgumentError) { release(dir, record, "A=#{'x' * 501}") }
      assert_includes error.message, "500"
      release(dir, record, "A=#{'x' * 500}")
      assert_equal "released", record.metadata["status"]
    end
  end

  def test_the_judgment_must_exist_be_complete_and_approving
    with_finished_record(outcome: "BLOCKED") do |dir, record|
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
      assert_includes error.message, "BLOCKED"
    end
    with_finished_record(outcome: "REJECTED") do |dir, record|
      assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
    end
    with_finished_record(outcome: "nothing decided") do |dir, record|
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
      assert_includes error.message, "final.md"
    end
    with_finished_record do |dir, record|
      record.update_handoff(record.control_plane.phase("judge")) { |h| h["status"] = "in_progress" }
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
      assert_includes error.message, "14-judgment is in_progress"
    end
    with_lifecycle_record(complete: LIFECYCLE - %w[judge]) do |dir, record|
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
      assert_includes error.message, "14-judgment"
    end
  end

  def test_closed_exploring_released_and_awaiting_human_records_are_refused
    %w[closed exploring awaiting_human].each do |status|
      with_finished_record(status: status) do |dir, record|
        before = tree_bytes(dir)
        error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
        assert_includes error.message, status
        assert_equal before, tree_bytes(dir)
      end
    end
    with_finished_record do |dir, record|
      release(dir, record, "A=a")
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "B=b") }
      assert_includes error.message, "already released"
    end
  end

  def test_a_failing_gate_refuses_the_release
    with_finished_record do |dir, record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "code changed after the evidence")
      error = assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a") }
      assert_includes error.message, "gate"
      assert_equal "in_progress", record.metadata["status"]
    end
  end

  def test_undischarged_judgment_items_are_carried_under_their_own_ids
    with_finished_record(undischarged: %w[U-1 U-2]) do |dir, record|
      release(dir, record, "GOLIVE-1=flag")
      items = record.release_items
      assert_equal %w[GOLIVE-1 U-1 U-2], items.map { |i| i["id"] }
      assert_equal %w[judgment judgment], items.select { |i| i["from"] }.map { |i| i["from"] }
      assert_equal "observe U-1 in production", items.find { |i| i["id"] == "U-1" }["description"]
      assert_equal 3, record.open_release_items.size
    end
  end

  def test_a_given_id_may_not_collide_with_a_carried_one
    with_finished_record(undischarged: %w[U-1]) do |dir, record|
      error = assert_raises(ArgumentError) { release(dir, record, "U-1=again") }
      assert_includes error.message, "U-1"
    end
  end

  def test_the_session_marker_refuses_release_and_discharge
    with_finished_record do |dir, record|
      before = tree_bytes(dir)
      assert_raises(SoftFoundry::TargetError) { release(dir, record, "A=a", env: { "SOFT_FOUNDRY_PHASE" => "review" }) }
      assert_equal before, tree_bytes(dir)
      release(dir, record, "A=a")
      before = tree_bytes(dir)
      error = assert_raises(SoftFoundry::TargetError) { release_for(dir, record).discharge("A", note: "done", env: { "SOFT_FOUNDRY_PHASE" => "review" }) }
      assert_includes error.message, "phase-run session"
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_discharge_records_time_commit_and_note
    with_finished_record do |dir, record|
      release(dir, record, "A=a", "B=b")
      release_for(dir, record).discharge("A", note: "observed on production", now: Time.utc(2026, 10, 25, 8, 30, 0))
      a = record.release_items.find { |i| i["id"] == "A" }
      assert_equal "2026-10-25T08:30:00Z", a["discharged_at"]
      assert_equal "observed on production", a["discharge_note"]
      assert_equal head(dir), a["discharge_commit"]
      assert_equal ["B"], record.open_release_items.map { |i| i["id"] }
      assert_equal "released", record.metadata["status"]
    end
  end

  def test_discharge_refusals_write_nothing
    with_finished_record do |dir, record|
      error = assert_raises(SoftFoundry::TargetError) { release_for(dir, record).discharge("A", note: "n") }
      assert_includes error.message, "not released"
      release(dir, record, "A=a")
      release_for(dir, record).discharge("A", note: "once")
      before = tree_bytes(dir)
      assert_raises(SoftFoundry::TargetError) { release_for(dir, record).discharge("A", note: "twice") }
      assert_raises(SoftFoundry::TargetError) { release_for(dir, record).discharge("ZZ", note: "unknown") }
      assert_raises(ArgumentError) { release_for(dir, record).discharge("A", note: "") }
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_the_lint_names_each_defect_in_a_released_record
    with_finished_record(undischarged: %w[U-1]) do |dir, record|
      lint = ->(meta) { SoftFoundry::Release.lint(meta, judgment_undischarged: %w[U-1]) }
      assert_equal [], lint.call("status" => "released", "release" => { "at" => "t", "commit" => "c", "items" => [{ "id" => "U-1", "description" => "d" }] })
      assert_match(/missing/, lint.call("status" => "released").join)
      assert_match(/not a mapping/, lint.call("status" => "released", "release" => "x").join)
      assert_match(/no items/, lint.call("status" => "released", "release" => { "at" => "t", "commit" => "c", "items" => [] }).join)
      assert_match(/at/, lint.call("status" => "released", "release" => { "commit" => "c", "items" => [{ "id" => "U-1", "description" => "d" }] }).join)
      assert_match(/duplicate id/, lint.call("status" => "released", "release" => { "at" => "t", "commit" => "c", "items" => [{ "id" => "U-1", "description" => "d" }, { "id" => "U-1", "description" => "e" }] }).join)
      assert_match(/description/, lint.call("status" => "released", "release" => { "at" => "t", "commit" => "c", "items" => [{ "id" => "U-1" }] }).join)
      assert_match(/U-1.*not carried|undischarged/, lint.call("status" => "released", "release" => { "at" => "t", "commit" => "c", "items" => [{ "id" => "X", "description" => "d" }] }).join)
      assert_equal [], SoftFoundry::Release.lint({ "status" => "closed" }, judgment_undischarged: [])
    end
  end

  def test_merged_unclosed_truth_table
    with_finished_record(merge: true, undischarged: []) do |dir, record|
      plane = SoftFoundry::ControlPlane.new(dir)
      index = SoftFoundry::ChangeIndex.new(dir, plane: plane, git: SoftFoundry::Git.new(dir))
      assert index.merged_unclosed?(record), "merged and in_progress"
      record.update_metadata { |m| m["status"] = "closed" }
      refute index.merged_unclosed?(record)
      record.update_metadata { |m| m["status"] = "released"; m["release"] = { "at" => "t", "commit" => "c", "items" => [{ "id" => "A", "description" => "a" }] } }
      refute index.merged_unclosed?(record), "released with an open item"
      record.update_metadata { |m| m["release"]["items"][0]["discharged_at"] = "t" }
      assert index.merged_unclosed?(record), "released with every item discharged"
      record.update_metadata { |m| m["release"] = nil }
      assert index.merged_unclosed?(record), "released with a malformed block"
    end
  end
end
