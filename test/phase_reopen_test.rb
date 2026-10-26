# frozen_string_literal: true

require_relative "lifecycle_fixture"

# PhaseReopen: the reset set, the byte-level promises about evidence, the
# history entry, and every refusal writing nothing.
class PhaseReopenTest < Minitest::Test
  include LifecycleFixture

  def reopen(dir, record, phase_id, reason: "fixture changed", source: "manual", env: {})
    plane = SoftFoundry::ControlPlane.new(dir)
    SoftFoundry::PhaseReopen.new(dir, plane: plane, git: SoftFoundry::Git.new(dir), record: record)
                            .call(plane.phase(phase_id), reason: reason, source: source, env: env)
  end

  def test_resets_the_phase_and_its_downstream_and_leaves_the_rest
    with_lifecycle_record(complete: LIFECYCLE - %w[judge]) do |dir, record|
      result = reopen(dir, record, "evaluate")
      assert_equal %w[evaluate attack review], result.reset.map(&:id)
      s = statuses(record)
      %w[evaluate attack review judge].each { |id| assert_equal "pending", s[id], id }
      %w[intake implement verify].each { |id| assert_equal "complete", s[id], id }
    end
  end

  def test_concurrent_reopens_reset_once_and_write_one_history_entry
    with_lifecycle_record do |dir, record|
      outcomes = Array.new(4) do
        Thread.new do
          reopen(dir, record, "verify")
          :ok
        rescue SoftFoundry::TargetError
          :refused
        end
      end.map(&:value)
      assert_equal 1, outcomes.count(:ok)
      assert_equal 1, Array(record.metadata["phase_reopenings"]).size
    end
  end

  def test_remediate_reopen_follows_the_transition_to_verify
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      result = reopen(dir, record, "remediate")
      assert_equal %w[verify evaluate attack remediate review judge], result.reset.map(&:id)
      assert_equal "complete", statuses(record)["implement"]
    end
  end

  def test_pending_phases_are_not_rewritten
    optional = %w[09-remediation 10-user-documentation 11-faq-index 12-observability]
    with_lifecycle_record do |dir, record|
      before = optional.map { |d| tree_bytes(dir, "changes/c1/#{d}") }
      result = reopen(dir, record, "attack")
      assert_equal %w[attack review judge], result.reset.map(&:id)
      assert_equal before, optional.map { |d| tree_bytes(dir, "changes/c1/#{d}") }
    end
  end

  def test_evidence_files_are_byte_identical_and_handoffs_are_cleared
    with_lifecycle_record do |dir, record|
      before = tree_bytes(dir)
      reopen(dir, record, "verify")
      after = tree_bytes(dir)
      changed = before.keys.select { |f| before[f] != after[f] }
      assert_equal [], after.keys - before.keys
      assert(changed.all? { |f| f.end_with?("/handoff.yml") || f == "changes/c1/metadata.yml" }, changed.inspect)
      %w[verify evaluate attack review judge].each do |id|
        h = record.handoff(record.control_plane.phase(id))
        assert_equal "pending", h["status"]
        assert_nil h["commit_sha"]
        assert_nil h["completed_at"]
        assert_nil h["executed_by"]
        assert_equal [], h["outputs"]
        assert_includes h["notes"], "reopened"
      end
      assert_equal "", sh(dir, "git", "status", "--porcelain", "--", "lib", "test")
    end
  end

  def test_history_entry_shape_and_the_exploring_list_untouched
    with_lifecycle_record do |dir, record|
      record.update_metadata { |m| m["reopenings"] = [{ "at" => "x", "reason" => "earlier" }] }
      commit_all(dir, "with reopenings")
      reopen(dir, record, "attack", reason: "needs a rerun")
      meta = record.metadata
      assert_equal [{ "at" => "x", "reason" => "earlier" }], meta["reopenings"]
      entry = meta["phase_reopenings"].fetch(0)
      assert_equal %w[at from_commit phase previous reason reset source], entry.keys.sort
      assert_equal "attack", entry["phase"]
      assert_equal %w[attack review judge], entry["reset"]
      assert_equal head(dir), entry["from_commit"]
      assert_equal "needs a rerun", entry["reason"]
      assert_equal "manual", entry["source"]
      prev = entry["previous"].fetch("attack")
      assert_equal %w[commit_sha completed_at session_id status], prev.keys.sort
      assert_equal "complete", prev["status"]
    end
  end

  def test_current_phase_is_the_reopened_phase_and_judged_becomes_in_progress
    with_lifecycle_record(status: "judged") do |dir, record|
      reopen(dir, record, "judge")
      assert_equal "in_progress", record.metadata["status"]
      assert_equal "judge", record.metadata["current_phase"]
    end
    with_lifecycle_record(status: "intake", current_phase: "judge") do |dir, record|
      reopen(dir, record, "review")
      assert_equal "intake", record.metadata["status"]
      assert_equal "review", record.metadata["current_phase"]
    end
  end

  def test_a_reopen_can_reach_back_to_specify
    with_lifecycle_record do |dir, record|
      result = reopen(dir, record, "specify")
      assert_equal %w[specify threat_model plan implement verify evaluate attack review judge], result.reset.map(&:id)
      assert_equal "complete", statuses(record)["discover"]
    end
  end

  def test_refusals_write_nothing
    { "closed" => /closed/, "released" => /released/, "exploring" => /exploring/, "awaiting_human" => /awaiting_human/ }.each do |status, pattern|
      with_lifecycle_record(status: status) do |dir, record|
        before = tree_bytes(dir)
        error = assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "attack") }
        assert_match pattern, error.message
        assert_equal before, tree_bytes(dir)
      end
    end
  end

  def test_bad_reasons_write_nothing
    with_lifecycle_record do |dir, record|
      before = tree_bytes(dir)
      ["", "   ", "a" * 501, "bad\nreason", "esc\e[0m"].each do |reason|
        assert_raises(ArgumentError) { reopen(dir, record, "attack", reason: reason) }
      end
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_nothing_to_reset_is_refused
    with_lifecycle_record(complete: %w[intake discover]) do |dir, record|
      before = tree_bytes(dir)
      error = assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "attack") }
      assert_includes error.message, "nothing to reset"
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_the_session_marker_refuses_a_manual_reopen_but_not_an_automatic_one
    with_lifecycle_record do |dir, record|
      before = tree_bytes(dir)
      error = assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "attack", env: { "SOFT_FOUNDRY_PHASE" => "evaluate" }) }
      assert_includes error.message, "phase-run session"
      assert_equal before, tree_bytes(dir)
      result = reopen(dir, record, "attack", source: "auto", env: { "SOFT_FOUNDRY_PHASE" => "evaluate" })
      assert_equal "auto", record.metadata["phase_reopenings"].last["source"]
      assert_equal %w[attack review judge], result.reset.map(&:id)
    end
  end

  def test_a_failure_while_staging_leaves_the_record_unchanged
    with_lifecycle_record do |dir, record|
      planted = record.handoff_path(record.control_plane.phase("review")) + SoftFoundry::SafeWrite::TMP_SUFFIX
      File.write(planted, "planted")
      before = tree_bytes(dir)
      assert_raises(SoftFoundry::TargetError) { reopen(dir, record, "attack") }
      assert_equal before, tree_bytes(dir)
      tree_bytes(dir).each { |f, bytes| YAML.safe_load(bytes, permitted_classes: [Time, Date]) if f.end_with?(".yml") }
    end
  end
end
