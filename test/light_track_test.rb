# frozen_string_literal: true

require_relative "lifecycle_fixture"

# changes/light-track: the light lifecycle track, normalized outside-change
# paths (process-speed REV-004), the round count (REV-005) and verify
# sizing for a text-only diff.
class LightTrackTest < Minitest::Test
  include LifecycleFixture

  LIGHT_REQUIRED = %w[intake specify implement verify review judge].freeze
  LIGHT_OPTIONAL = %w[discover threat_model plan evaluate attack learn].freeze

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)

  def gate(dir, record, phase_id)
    SoftFoundry::Gate.new(record, git: git(dir)).evaluate(plane(dir).phase(phase_id))
  end

  def check(result, name) = result.checks.find { |c| c.name == name }

  # A new-rules record on `track` at `risk`, with `complete` phases planted
  # and committed.
  def with_track_record(track, risk: "medium", complete: LIGHT_REQUIRED)
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      code, out = cli(dir, "change", "new", "c1", "--track", track)
      assert_equal 0, code, out
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane(dir))
      set_metadata!(record, status: "in_progress", current_phase: "judge")
      record.update_metadata { |m| m["risk"] = risk }
      commit_all(dir, "record")
      complete.each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases complete") unless complete.empty?
      yield dir, record
    end
  end

  def review_findings!(record, findings)
    record.update_handoff(record.control_plane.phase("review")) { |h| h["findings"] = findings }
  end

  def sealed_rounds!(dir, record, rounds)
    rounds.times do |i|
      File.write(File.join(record.dir, "09-remediation", "round-#{i}.md"), "round #{i}\n")
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "Record #{record.slug} remediate")
    end
  end

  # --- REQ-001 / REQ-002 (AC-001) -------------------------------------------

  def test_light_track_names_its_optional_phases
    with_fixture_repo do |dir|
      track = plane(dir).track("light")
      refute_nil track, "light track is defined"
      assert_equal LIGHT_OPTIONAL.sort, track.optional.sort
      refute track.exploring?
    end
  end

  def test_a_light_record_passes_its_gates_and_closes_without_the_optional_phases
    with_track_record("light") do |dir, record|
      p = plane(dir)
      LIGHT_OPTIONAL.each { |id| assert_equal "pending", record.phase_status(p.phase(id)), id }
      %w[specify implement verify review judge].each do |id|
        c = check(gate(dir, record, id), "predecessor complete")
        assert_equal :pass, c.outcome, "#{id}: #{c.detail}"
      end
      assert record.reached_lifecycle_end?
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
      code, out = cli(dir, "change", "close", "c1")
      assert_equal 0, code, out
      assert_includes out, "closed"
    end
  end

  def test_the_same_record_on_the_gated_track_is_not_finished
    with_track_record("gated") do |dir, record|
      refute record.reached_lifecycle_end?
      c = check(gate(dir, record, "review"), "predecessor complete")
      assert_equal :fail, c.outcome
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
      code, = cli(dir, "change", "close", "c1")
      refute_equal 0, code
    end
  end

  # --- REQ-003 / REQ-004 (AC-002) -------------------------------------------

  def test_a_light_record_keeps_the_specification_lock
    with_track_record("light") do |dir, record|
      path = File.join(record.dir, "02-specification", "specification.md")
      File.write(path, "#{File.read(path)}\nA requirement added after the lock.\n")
      commit_all(dir, "edit the specification")
      c = check(gate(dir, record, "specify"), "specification locked")
      assert_equal :fail, c.outcome, c.detail
    end
  end

  def test_a_light_record_needs_the_must_list_approved
    with_track_record("light") do |dir, record|
      record.update_metadata { |m| m["human_decisions"] = [] }
      c = check(gate(dir, record, "specify"), "must criteria approved")
      assert_equal :fail, c.outcome, c.detail
    end
  end

  def test_a_light_record_is_held_to_the_remediation_cap
    with_track_record("light", complete: LIGHT_REQUIRED + %w[remediate]) do |dir, record|
      sealed_rounds!(dir, record, 2)
      p = plane(dir)
      error = assert_raises(SoftFoundry::TargetError) do
        SoftFoundry::PhaseReopen.new(dir, plane: p, git: git(dir), record: record).call(p.phase("remediate"), reason: "more findings", source: "manual", env: {})
      end
      assert_includes error.message, "remediation cap"
      assert_equal :fail, check(gate(dir, record, "review"), "remediation within cap").outcome
    end
  end

  def test_a_high_risk_record_cannot_be_light
    with_track_record("light", risk: "high", complete: %w[intake]) do |dir, record|
      c = check(gate(dir, record, "intake"), "track permitted")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "gated"
    end
  end

  # --- REQ-005 (AC-003) -------------------------------------------------------

  def test_outside_change_paths_are_normalized_before_comparison
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "change app")
      absolute = File.join(dir, "lib", "app.rb")
      ["./lib/app.rb", "lib//app.rb", "lib/./app.rb", "lib/x/../app.rb", "lib/app.rb ", absolute, "lib/*.rb", "../outside.rb"].each do |spelling|
        review_findings!(record, [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "x", "paths" => [spelling] }])
        c = check(gate(dir, record, "review"), "outside-change findings")
        assert_equal :fail, c.outcome, "#{spelling.inspect}: #{c.detail}"
        assert_includes c.detail, spelling.strip
      end
      review_findings!(record, [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "x", "paths" => ["./lib/other.rb"] }])
      assert_equal :pass, check(gate(dir, record, "review"), "outside-change findings").outcome
    end
  end

  # --- REQ-006 (AC-004) -------------------------------------------------------

  def test_an_unsealed_remediation_is_not_a_round
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      sealed_rounds!(dir, record, 1)
      record.update_metadata do |m|
        m["phase_reopenings"] = [
          { "phase" => "remediate", "reset" => %w[verify remediate], "previous" => { "remediate" => { "status" => "complete", "sealed" => true } } },
          { "phase" => "remediate", "reset" => %w[verify remediate], "previous" => { "remediate" => { "status" => "complete", "sealed" => false } } },
          { "phase" => "remediate", "reset" => %w[verify remediate], "previous" => { "remediate" => { "status" => "in_progress" } } }
        ]
      end
      rules = SoftFoundry::ProcessRules.new(record, git: git(dir))
      assert_equal 1, rules.remediation_rounds
      assert rules.another_round_allowed?
    end
  end

  def test_a_reopen_records_whether_the_remediation_was_sealed
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      p = plane(dir)
      SoftFoundry::PhaseReopen.new(dir, plane: p, git: git(dir), record: record).call(p.phase("remediate"), reason: "more findings", source: "manual", env: {})
      entry = Array(record.metadata["phase_reopenings"]).last
      assert_equal true, entry.dig("previous", "remediate", "sealed")
    end
  end

  def test_the_cap_message_says_rounds_and_gives_the_count
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      sealed_rounds!(dir, record, 2)
      message = SoftFoundry::ProcessRules.new(record, git: git(dir)).cap_refusal
      assert_includes message, "2 remediation rounds"
      refute_includes message, "sealed"
    end
  end

  # --- REQ-007 (AC-005) -------------------------------------------------------

  def test_a_text_only_diff_gets_the_smaller_verify_size_without_a_plan
    with_track_record("light", complete: %w[intake specify]) do |dir, record|
      File.write(File.join(dir, "README.md"), "# readme\n")
      FileUtils.mkdir_p(File.join(dir, "docs"))
      File.write(File.join(dir, "docs", "guide.md"), "guide\n")
      skill = File.join(dir, ".ai", "skills", "review", "SKILL.md")
      File.write(skill, "#{File.read(skill)}\nOne more sentence.\n")
      File.write(File.join(record.dir, "05-implementation", "log.md"), "log\n")
      commit_all(dir, "text")
      sizing = SoftFoundry::Sizing.new(record, git: git(dir))
      result = sizing.compute("verify")
      assert_equal sizing.sizes("verify").first, result.size, result.reasons.join("; ")
      assert_includes result.reasons.join, "documentation-only"
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      commit_all(dir, "code")
      assert_equal sizing.sizes("verify").last, sizing.compute("verify").size
    end
  end

  def test_control_plane_settings_are_not_text
    with_fixture_repo do |dir|
      p = plane(dir)
      %w[README.md docs/x.md changes/c1/notes.md .ai/skills/review/SKILL.md .ai/README.md].each { |path| assert SoftFoundry::ProcessRules.text_only_path?(p, path, "c1"), path }
      %w[.ai/workflow.yml .ai/skills/review/permissions.yml .ai/harness-evals/cases/x.md lib/x.rb test/x_test.rb].each { |path| refute SoftFoundry::ProcessRules.text_only_path?(p, path, "c1"), path }
      refute SoftFoundry::ProcessRules.documentation_path?(p, ".ai/skills/review/SKILL.md", "c1")
    end
  end

  # --- REQ-011 / REQ-012 (AC-008, AC-009) -------------------------------------

  def test_an_unknown_track_is_refused_with_the_defined_tracks
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      code, out = cli(dir, "change", "new", "c1", "--track", "nosuch")
      refute_equal 0, code
      %w[gated iterative light].each { |name| assert_includes out, name }
    end
  end

  def test_status_names_the_track_and_labels_stepped_over_phases_in_words
    with_track_record("light") do |dir, record|
      _code, out, = run_cli(dir, "change", "status", "c1", env: { "NO_COLOR" => "1" })
      assert_includes out, "track: light"
      plain = out.gsub(/[^\x20-\x7E\n]/, "")
      %w[01-discovery 03-threat-model 07-evaluation 08-attack].each do |output|
        line = plain.lines.find { |l| l.include?(output) }
        assert_includes line, "optional on the light track", output
      end
      assert_includes plain.lines.find { |l| l.include?("09-remediation") }, "optional"
    end
  end

  def test_help_names_the_light_track
    with_fixture_repo do |dir|
      _code, out = cli(dir, "help")
      assert_includes out, "--track gated|iterative|light"
    end
  end
end
