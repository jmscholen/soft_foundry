# frozen_string_literal: true

require "json"
require_relative "test_helper"

class SnapshotTest < Minitest::Test
  include FoundryFixture

  def with_snapshot
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      cli(dir, "change", "new", "c1", "--title", "First change")
      commit_all(dir, "record c1")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
      yield dir, record, SoftFoundry::Snapshot.new(dir, plane: plane, git: SoftFoundry::Git.new(dir))
    end
  end

  def edit_yaml(path)
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date])
    yield data
    File.write(path, YAML.dump(data))
  end

  def gate(change, phase) = change["gates"].find { |g| g["phase"] == phase }

  # Everything a snapshot returns is plain data: it survives a JSON round
  # trip unchanged, so no Time, Symbol, or Data object leaks out.
  def assert_plain(value)
    assert_equal value, JSON.parse(JSON.generate(value))
  end

  def test_workflow_describes_phases_transitions_and_tracks
    with_snapshot do |_dir, _record, snapshot|
      workflow = snapshot.workflow
      assert_plain workflow
      assert_equal 1, workflow["version"]
      assert_equal 16, workflow["phases"].size

      intake = workflow["phases"].first
      assert_equal "intake", intake["id"]
      assert_equal "00-intake", intake["output"]
      assert_equal "discover", intake["next"]
      refute intake["hardening"]
      assert_includes intake["required_files"], "request.md"
      assert_includes intake["checks"].map { |c| c["name"] }, "required files present"
      assert intake["checks"].all? { |c| !c["description"].to_s.empty? }

      verify = workflow["phases"].find { |p| p["id"] == "verify" }
      assert verify["hardening"]
      assert verify["commit_bound"]
      assert_includes verify["checks"].map { |c| c["name"] }, "evidence current"
      assert_includes verify["checks"].map { |c| c["name"] }, "red evidence"

      remediate = workflow["phases"].find { |p| p["id"] == "remediate" }
      assert remediate["optional"]
      assert_equal "implement", remediate["after"]
      assert_equal "verify", remediate["next"]
      assert_equal "done", workflow["phases"].last["next"]

      assert_equal "remediate", workflow.dig("transitions", "review", "on_blocking_findings")
      assert_includes workflow["judgments"], "APPROVED"
      assert_equal "gated", workflow.dig("tracks", "default")
      assert_equal({ "high" => "gated" }, workflow.dig("tracks", "forced_by_risk"))
      iterative = workflow.dig("tracks", "list").find { |t| t["name"] == "iterative" }
      assert iterative["exploring"]
      assert_equal %w[intake specify], iterative["vet_requires"]
    end
  end

  # The workflow's list of checks per phase is what the explainer shows,
  # so it must name every check the gate really runs on a complete phase.
  def test_workflow_checks_cover_what_the_gate_runs
    with_snapshot do |dir, record, snapshot|
      complete_phase!(record, "intake", sha: head(dir))
      ran = gate(snapshot.change("c1"), "intake")["checks"].map { |c| c["name"] }
      listed = snapshot.workflow["phases"].first["checks"].map { |c| c["name"] }
      assert_empty ran - listed
    end
  end

  # Carried from ui-snapshot's review (REV-004): every phase, not only the
  # first, lists the checks its gate runs.
  def test_workflow_checks_cover_what_the_gate_runs_for_every_phase
    with_snapshot do |dir, record, snapshot|
      record.control_plane.phases.each { |phase| complete_phase!(record, phase.id, sha: head(dir)) }
      edit_yaml(File.join(record.dir, "metadata.yml")) { |m| m["vetted"] = { "at" => "2030-01-02T10:00:00Z", "by" => "Ada", "commit" => head(dir) } }
      listed = snapshot.workflow["phases"].to_h { |p| [p["id"], p["checks"].map { |c| c["name"] }] }
      snapshot.change("c1")["gates"].each do |g|
        assert_empty g["checks"].map { |c| c["name"] } - listed.fetch(g["phase"]), g["phase"]
      end
    end
  end

  def test_change_reports_each_gate_with_its_checks
    with_snapshot do |dir, record, snapshot|
      complete_phase!(record, "intake", sha: head(dir))
      complete_phase!(record, "specify", sha: head(dir))
      change = snapshot.change("c1")
      assert_plain change
      assert_equal "c1", change["slug"]
      assert_equal "First change", change["title"]
      assert_equal 16, change["gates"].size

      intake = gate(change, "intake")
      assert_equal "complete", intake["status"]
      assert_equal "pass", intake["state"]
      assert_equal "pass", intake["checks"].find { |c| c["name"] == "required files present" }["outcome"]
      assert_equal "2026-09-09T00:00:00Z", intake["completed_at"]

      assert_equal "pending", gate(change, "discover")["state"]
      specify = gate(change, "specify")
      assert_equal "fail", specify["state"]
      assert_equal "fail", specify["checks"].find { |c| c["name"] == "predecessor complete" }["outcome"]
      assert change["failed"]
    end
  end

  def test_stale_in_progress_blocked_and_missing_states
    with_snapshot do |dir, record, snapshot|
      plane = record.control_plane
      %w[intake discover specify threat_model plan implement verify].each { |id| complete_phase!(record, id, sha: head(dir)) }
      edit_yaml(record.handoff_path(plane.phase("evaluate"))) { |h| h["status"] = "in_progress" }
      edit_yaml(record.handoff_path(plane.phase("attack"))) { |h| h.merge!("status" => "blocked", "blocking" => ["waiting on a person"]) }
      FileUtils.rm(record.handoff_path(plane.phase("learn")))
      commit_all(dir, "phases")
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")

      change = snapshot.change("c1")
      assert_equal "stale", gate(change, "verify")["state"]
      assert_equal "in_progress", gate(change, "evaluate")["state"]
      assert_equal "blocked", gate(change, "attack")["state"]
      assert_equal ["waiting on a person"], gate(change, "attack")["blocking"]
      assert_equal "missing", gate(change, "learn")["state"]
      assert_equal "missing", gate(change, "learn")["status"]
    end
  end

  def test_pending_phases_say_why_they_may_stay_pending
    with_snapshot do |dir, record, snapshot|
      edit_yaml(File.join(record.dir, "metadata.yml")) do |m|
        m["skipped_phases"] = [{ "phase" => "plan", "rationale" => "small change" }]
      end
      change = snapshot.change("c1")
      assert_equal "waived", gate(change, "plan")["skip_reason"]
      assert_equal "small change", gate(change, "plan")["skip_rationale"]
      assert_equal "optional", gate(change, "remediate")["skip_reason"]
      assert_nil gate(change, "discover")["skip_reason"]
      assert_equal [{ "phase" => "plan", "rationale" => "small change" }], change["skipped_phases"]

      cli(dir, "change", "new", "c2", "--title", "x", "--track", "iterative")
      explored = snapshot.change("c2")
      assert_equal "track", gate(explored, "discover")["skip_reason"]
      assert explored.dig("track", "exploring")
      assert explored.dig("track", "exploring_stage")
      assert_equal 0, explored.dig("track", "iterations")
    end
  end

  def test_track_reports_vet_and_forced_risk
    with_snapshot do |_dir, record, snapshot|
      edit_yaml(File.join(record.dir, "metadata.yml")) do |m|
        m["risk"] = "high"
        m["vetted"] = { "at" => "2026-09-20T10:00:00Z", "by" => "Ada", "commit" => "abc1234" }
      end
      track = snapshot.change("c1")["track"]
      assert_equal "gated", track["name"]
      assert track["defined"]
      refute track["exploring"]
      assert_equal "gated", track["forced_by_risk"]
      assert_equal({ "at" => "2026-09-20T10:00:00Z", "by" => "Ada", "commit" => "abc1234" }, track["vetted"])
    end
  end

  def test_timestamps_are_iso_strings_and_local_paths_are_left_out
    with_snapshot do |dir, _record, snapshot|
      change = snapshot.change("c1")
      assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, change["created_at"])
      assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, change["generated_at"])
      refute_includes JSON.generate(change), dir
      refute_includes JSON.generate(snapshot.board), dir
    end
  end

  def test_timeline_orders_recorded_events
    with_snapshot do |dir, record, snapshot|
      plane = record.control_plane
      complete_phase!(record, "intake", sha: head(dir))
      edit_yaml(record.handoff_path(plane.phase("intake"))) do |h|
        h["started_at"] = "2030-01-01T09:00:00Z"
        h["completed_at"] = "2030-01-01T10:00:00Z"
      end
      edit_yaml(File.join(record.dir, "metadata.yml")) do |m|
        m["vetted"] = { "at" => "2030-01-02T10:00:00Z", "by" => "Ada", "commit" => "abc1234" }
        m["reopenings"] = [{ "at" => "2030-01-03T10:00:00Z", "from_commit" => "abc1234", "reason" => "reshape" }]
        m["human_decisions"] = [{ "boundary" => "legal commitment", "subject" => "terms", "decided_by" => "Ada", "decided_at" => "2030-01-04T10:00:00Z", "decision" => "approved" }]
      end
      SoftFoundry::Budget.new(record).record!(phase: "intake", provider: "anthropic", model: "m", tokens_in: 1, tokens_out: 2, estimated_usd: 0.5, now: Time.utc(2030, 1, 5))

      timeline = snapshot.change("c1")["timeline"]
      assert_plain timeline
      assert_equal %w[created started completed vetted reopened human_decision spend], timeline.map { |e| e["kind"] }
      assert_equal "intake", timeline[1]["phase"]
      assert_equal "2030-01-01T10:00:00Z", timeline[2]["at"]
      assert_includes timeline[4]["label"], "reshape"
      assert timeline.all? { |e| e["at"].is_a?(String) && !e["label"].to_s.empty? }
    end
  end

  # Carried from ui-snapshot's review (REV-002): a recorded "time" that
  # is a placeholder or free text is not an event on a timeline.
  def test_timeline_leaves_out_events_whose_time_is_not_a_time
    with_snapshot do |dir, record, snapshot|
      complete_phase!(record, "intake", sha: head(dir))
      edit_yaml(record.handoff_path(record.control_plane.phase("intake"))) do |h|
        h["started_at"] = "TBD"
        h["completed_at"] = "2030-01-01T10:00:00Z"
      end
      edit_yaml(File.join(record.dir, "metadata.yml")) do |m|
        m["human_decisions"] = [{ "boundary" => "legal commitment", "subject" => "terms", "decided_by" => "Ada", "decided_at" => "soon", "decision" => "approved" }]
        m["reopenings"] = [{ "at" => "2030-01-03", "from_commit" => "abc1234", "reason" => "reshape" }]
      end
      timeline = snapshot.change("c1")["timeline"]
      assert_equal %w[created completed reopened], timeline.map { |e| e["kind"] }
      assert_equal "2030-01-03", timeline.last["at"]
    end
  end

  def test_spend_flags_what_is_over_its_cap
    with_snapshot do |_dir, record, snapshot|
      edit_yaml(File.join(record.dir, "metadata.yml")) { |m| m["risk"] = "low" }
      policy = SoftFoundry::Budget.policy(record.control_plane, risk: "low")
      budget = SoftFoundry::Budget.new(record)
      budget.record!(phase: "intake", provider: "anthropic", model: "m", tokens_in: 1, tokens_out: 1, estimated_usd: policy.max_usd_per_phase + 1)
      budget.record!(phase: "verify", provider: "anthropic", model: "m", tokens_in: 1, tokens_out: 1, estimated_usd: 0.01)
      spend = snapshot.change("c1")["spend"]
      assert spend["by_phase"].find { |p| p["phase"] == "intake" }["over_cap"]
      refute spend["by_phase"].find { |p| p["phase"] == "verify" }["over_cap"]
      assert_equal spend.dig("totals", "estimated_usd") > policy.max_usd_per_change, spend.dig("totals", "over_cap")
      assert_includes [true, false], spend.dig("totals", "needs_approval")
    end
  end

  def test_spend_totals_group_by_phase_and_carry_the_policy
    with_snapshot do |_dir, record, snapshot|
      edit_yaml(File.join(record.dir, "metadata.yml")) { |m| m["risk"] = "low" }
      budget = SoftFoundry::Budget.new(record)
      budget.record!(phase: "intake", provider: "anthropic", model: "m", tokens_in: 100, tokens_out: 10, estimated_usd: 1.25)
      budget.record!(phase: "intake", provider: "anthropic", model: "m", tokens_in: 50, tokens_out: 5, estimated_usd: 0.75)
      budget.record!(phase: "verify", provider: "openai", model: "n", tokens_in: 7, tokens_out: 3)

      spend = snapshot.change("c1")["spend"]
      assert_plain spend
      assert_equal 157, spend.dig("totals", "tokens_in")
      assert_in_delta 2.0, spend.dig("totals", "estimated_usd")
      assert_equal 1, spend.dig("totals", "entries_missing_cost")
      assert_equal 3, spend["entries"].size

      intake = spend["by_phase"].find { |p| p["phase"] == "intake" }
      assert_equal 150, intake["tokens_in"]
      assert_in_delta 2.0, intake["estimated_usd"]
      assert_equal 2, intake["entries"]
      verify = spend["by_phase"].find { |p| p["phase"] == "verify" }
      assert_nil verify["estimated_usd"]
      policy = SoftFoundry::Budget.policy(record.control_plane, risk: "low")
      assert_in_delta policy.max_usd_per_change, spend.dig("policy", "max_usd_per_change")
      assert_in_delta policy.max_usd_per_phase, spend.dig("policy", "max_usd_per_phase")
    end
  end

  def test_change_lists_advisories
    with_snapshot do |_dir, record, snapshot|
      edit_yaml(File.join(record.dir, "metadata.yml")) do |m|
        m["skipped_phases"] = [{ "phase" => "review", "rationale" => "none needed" }]
      end
      advisories = snapshot.change("c1")["advisories"]
      assert_equal 1, advisories.size
      assert_equal "review", advisories.first["area"]
      refute_empty advisories.first["message"]
    end
  end

  def test_board_has_a_row_per_change_and_a_cell_per_phase
    with_snapshot do |dir, record, snapshot|
      complete_phase!(record, "intake", sha: head(dir))
      board = snapshot.board
      assert_plain board
      assert_equal 1, board["version"]
      assert_equal "main", board["default_branch"]
      assert_equal 16, board["phases"].size
      row = board["changes"].find { |c| c["slug"] == "c1" }
      assert row["evaluated"]
      refute row["closed"]
      refute row["failed"]
      refute row["merged_unclosed"]
      assert_equal "First change", row["title"]
      assert_equal 16, row["cells"].size
      assert_equal({ "phase" => "intake", "status" => "complete", "state" => "pass", "skip_reason" => nil }, row["cells"].first)
    end
  end

  # A closed record is settled history: the board reports what its
  # handoffs recorded and does not spend a gate run on it.
  def test_board_does_not_gate_a_closed_record
    with_snapshot do |dir, record, snapshot|
      complete_phase!(record, "specify", sha: head(dir))
      assert snapshot.board["changes"].first["failed"], "an open record with a failing gate"

      record.close!
      row = snapshot.board["changes"].first
      assert row["closed"]
      refute row["evaluated"]
      refute row["failed"]
      assert_equal "complete", row["cells"].find { |c| c["phase"] == "specify" }["state"]
    end
  end

  def test_board_flags_stale_and_merged_unclosed_records
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
      commit_all(dir, "record c1")
      sha = head(dir)
      %w[intake discover specify threat_model plan implement verify evaluate attack review judge learn].each { |id| complete_phase!(record, id, sha: sha) }
      commit_all(dir, "complete c1")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
      snapshot = SoftFoundry::Snapshot.new(dir, plane: plane, git: SoftFoundry::Git.new(dir))

      row = snapshot.board["changes"].first
      assert row["merged_unclosed"]
      refute row["stale"]

      # Staleness is measured on the record's own branch.
      sh(dir, "git", "checkout", "-q", "change/c1")
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      assert snapshot.board["changes"].first["stale"]
    end
  end

  # Change records are input someone else may have written. One that
  # cannot be read is reported in its row, and the rest still load.
  def test_board_reports_an_unreadable_record_without_failing
    with_snapshot do |dir, record, snapshot|
      cli(dir, "change", "new", "broken", "--title", "x")
      File.write(File.join(dir, "changes", "broken", "metadata.yml"), "change: [unterminated\n")
      rows = snapshot.board["changes"]
      broken = rows.find { |c| c["slug"] == "broken" }
      refute_empty broken["error"]
      refute_includes broken["error"], dir
      refute broken.key?("cells")
      assert_equal 16, rows.find { |c| c["slug"] == record.slug }["cells"].size
    end
  end

  # Found by ATTACK-008: a metadata.yml that is valid YAML but not a
  # mapping (here, a symlink to a plain text file) was reported with a
  # Ruby error. It is named for what it is, and none of it is repeated.
  def test_a_metadata_file_that_is_not_a_mapping_is_named_plainly
    with_snapshot do |dir, _record, snapshot|
      outside = File.join(dir, "outside.txt")
      File.write(outside, "root:x:0:0:secret line\n")
      FileUtils.mkdir_p(File.join(dir, "changes", "linked"))
      File.symlink(outside, File.join(dir, "changes", "linked", "metadata.yml"))

      row = snapshot.board["changes"].find { |c| c["slug"] == "linked" }
      assert_equal "changes/linked/metadata.yml is not a mapping", row["error"]
      error = assert_raises(RuntimeError) { snapshot.change("linked") }
      assert_equal "changes/linked/metadata.yml is not a mapping", error.message
      refute_includes JSON.generate(snapshot.board), "secret line"
    end
  end

  # YAML refuses a file that is not UTF-8, so a record's text is valid by
  # the time it is read; anything else that reaches a snapshot (a path in
  # an error, a binary string) is still made safe to serialize.
  def test_plain_makes_any_recorded_value_safe_to_serialize
    plain = SoftFoundry::Snapshot.plain(
      "text" => "caf\xFF".b, :symbol => :value, "time" => Time.utc(2030, 1, 2, 3, 4, 5), "date" => Date.new(2030, 1, 2),
      "nested" => [1, 2.5, true, nil, Float::NAN]
    )
    assert_plain plain
    assert_equal "caf?", plain["text"]
    assert_equal "value", plain["symbol"]
    assert_equal "2030-01-02T03:04:05Z", plain["time"]
    assert_equal "2030-01-02", plain["date"]
    assert_equal [1, 2.5, true, nil, nil], plain["nested"]
  end
end
