# frozen_string_literal: true

require_relative "lifecycle_fixture"

# changes/process-speed at the command line: `phase reopen` at the cap and
# with --docs-only, `phase run` refusing a capped or parked change, the
# workflow keys `check` lints, and the follow-up advisory.
class CliProcessSpeedTest < Minitest::Test
  include LifecycleFixture

  def sealed_rounds!(dir, record, rounds)
    rounds.times do |i|
      File.write(File.join(record.dir, "09-remediation", "round-#{i}.md"), "round #{i}\n")
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "Record #{record.slug} remediate")
    end
  end

  def test_reopen_at_the_cap_exits_non_zero_and_names_the_decisions
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      sealed_rounds!(dir, record, 2)
      code, out, err = run_cli(dir, "phase", "reopen", "remediate", "--reason", "judgment blocked again")
      refute_equal 0, code
      text = out + err
      %w[accept_residual narrow reject awaiting_human].each { |w| assert_includes text, w }
      assert_equal "awaiting_human", record.metadata["status"]
    end
  end

  def test_reopen_docs_only_from_the_command_line
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      sealed_rounds!(dir, record, 1)
      code, out, err = run_cli(dir, "phase", "reopen", "remediate", "--docs-only", "--reason", "wording only")
      assert_equal 0, code, err
      assert_includes out, "documentation-only"
      refute_includes out, "reset verify"
      assert_equal true, record.metadata["phase_reopenings"].last["docs_only"]
    end
  end

  def test_docs_only_is_refused_for_another_phase
    with_lifecycle_record(complete: LIFECYCLE) do |dir, _record|
      code, _out, err = run_cli(dir, "phase", "reopen", "verify", "--docs-only", "--reason", "x y")
      refute_equal 0, code
      assert_includes err, "--docs-only applies to `phase reopen remediate` only"
    end
  end

  def test_phase_run_does_not_start_a_session_for_a_parked_change
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate], status: "awaiting_human") do |dir, _record|
      launched = false
      code, _out, err = run_cli(dir, "phase", "run", "review", "--shell", "claude", runner: ->(_l) { launched = true; 0 })
      refute_equal 0, code
      refute launched
      assert_includes err, "awaiting_human"
    end
  end

  def test_phase_run_auto_reopen_at_the_cap_starts_no_session
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      sealed_rounds!(dir, record, 2)
      File.write(File.join(dir, "lib", "app.rb"), "puts 9\n")
      commit_all(dir, "code after remediation")
      launched = false
      # Remediation is not commit-bound, so it is never stale itself; the
      # automatic reopen that reaches it is a stale verify, whose reset
      # includes remediation (deviation DEV-001 from AC-003's wording).
      code, out, err = run_cli(dir, "phase", "run", "verify", "--shell", "claude", runner: ->(_l) { launched = true; 0 })
      refute_equal 0, code, out + err
      refute launched
      assert_includes out + err, "remediation cap"
      assert_equal "awaiting_human", record.metadata["status"]
    end
  end

  def test_check_lints_the_convergence_keys
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai", "workflow.yml")
      File.write(path, "#{File.read(path)}\nremediation:\n  max_rounds: 0\nmust_criteria_cap: three\n")
      code, out, err = run_cli(dir, "check")
      refute_equal 0, code
      assert_includes out + err, "remediation.max_rounds"
      assert_includes out + err, "must_criteria_cap"
    end
  end

  def test_outside_change_finding_is_listed_as_a_follow_up
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      record.update_handoff(record.control_plane.phase("review")) do |h|
        h["findings"] = [{ "id" => "REV-007", "severity" => "major", "summary" => "guard escape", "failure" => "f", "outside_change" => true, "follow_up" => "guard follow-up change", "paths" => ["lib/guard.rb"] }]
      end
      _code, out, err = run_cli(dir, "change", "status")
      assert_match(/follow-up.*REV-007/, out + err)
    end
  end
end
