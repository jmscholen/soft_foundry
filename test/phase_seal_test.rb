# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `soft-foundry phase seal <phase>`: gates the phase and, on pass, commits
# its directory and the record's metadata in one commit the tool makes,
# so no person has to commit a phase for the specification lock and the
# plan diff base to exist (REQ-001 to REQ-004, REQ-020, REQ-033, REQ-034).
class PhaseSealTest < Minitest::Test
  include LifecycleFixture

  def seal(dir, *args, env: {})
    run_cli(dir, "phase", "seal", *args, env: env)
  end

  def log(dir) = sh(dir, "git", "log", "--format=%s", "-n", "3").lines.map(&:chomp)
  def files_in_head(dir) = sh(dir, "git", "show", "--name-only", "--format=", "HEAD").lines.map(&:chomp).reject(&:empty?)
  # The record lock directory is machine-local state the fixture repository does not ignore.
  def dirty(dir) = sh(dir, "git", "status", "--porcelain").lines.map(&:chomp).reject { |l| l.include?(".soft-foundry/") }
  def meta(record) = record.metadata

  # A record with the named phases sealed (complete and committed) and
  # `pending_phase` complete on disk only.
  def with_unsealed(pending_phase, sealed: [], **opts)
    with_lifecycle_record(complete: sealed, current_phase: pending_phase, **opts) do |dir, record|
      complete_phase!(record, pending_phase, sha: head(dir))
      yield dir, record
    end
  end

  def test_seal_commits_phase_and_metadata_and_advances
    with_unsealed("intake", status: "intake") do |dir, record|
      code, out, err = seal(dir, "intake")
      assert_equal 0, code, out + err
      assert_equal "Record c1 intake", log(dir).first
      assert_equal ["changes/c1/00-intake/handoff.yml", "changes/c1/metadata.yml"].sort, files_in_head(dir).select { |f| f.end_with?("handoff.yml", "metadata.yml") }.sort
      assert files_in_head(dir).all? { |f| f.start_with?("changes/c1/00-intake/") || f == "changes/c1/metadata.yml" }, files_in_head(dir).inspect
      assert_equal "discover", meta(record)["current_phase"]
      assert_equal "in_progress", meta(record)["status"]
      assert_match(/\Asealed 00-intake at [0-9a-f]{12}/, out.lines.last)
      assert_empty dirty(dir)
    end
  end

  def test_gate_failure_commits_nothing
    with_unsealed("intake", status: "intake") do |dir, record|
      File.write(File.join(record.dir, "00-intake", "request.md"), "# Change Intake\n\n## User intent\nTBD\n")
      before = log(dir)
      code, out, err = seal(dir, "intake")
      assert_equal 2, code, out + err
      assert_includes out + err, "no placeholders"
      assert_equal before, log(dir)
      assert_equal "intake", meta(record)["current_phase"]
    end
  end

  def test_refuses_incomplete_handoff
    with_lifecycle_record(complete: [], current_phase: "intake", status: "intake") do |dir, record|
      record.update_handoff(record.control_plane.phase("intake")) { |h| h["status"] = "in_progress" }
      before = log(dir)
      code, out, err = seal(dir, "intake")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "in_progress"
      assert_includes out + err, "complete"
      assert_equal before, log(dir)
    end
  end

  def test_refuses_dirty_code_paths
    with_unsealed("implement", sealed: %w[intake discover specify threat_model plan]) do |dir, _record|
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      before = log(dir)
      code, out, err = seal(dir, "implement")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "lib/app.rb"
      assert_includes out + err, "commit"
      assert_equal before, log(dir)
    end
  end

  def test_leaves_unrelated_dirty_file_and_notes_it
    with_unsealed("specify", sealed: %w[intake discover]) do |dir, _record|
      File.write(File.join(dir, "scratch.txt"), "notes\n")
      code, out, err = seal(dir, "specify")
      assert_equal 0, code, out + err
      refute_includes files_in_head(dir), "scratch.txt"
      assert_includes dirty(dir), "?? scratch.txt"
      assert(out.lines.any? { |l| l.start_with?("note:") && l.include?("scratch.txt") }, out)
    end
  end

  def test_stages_only_the_phase_and_metadata
    with_unsealed("plan", sealed: %w[intake discover specify threat_model]) do |dir, record|
      planted = File.join(record.dir, "06-verification", "planted.txt")
      File.write(planted, "x\n")
      code, out, err = seal(dir, "plan")
      assert_equal 0, code, out + err
      refute_includes files_in_head(dir), "changes/c1/06-verification/planted.txt"
      assert_includes dirty(dir), "?? changes/c1/06-verification/planted.txt"
    end
  end

  def test_judge_seal_sets_status_judged
    with_unsealed("judge", sealed: LIFECYCLE - %w[judge]) do |dir, record|
      code, out, err = seal(dir, "judge")
      assert_equal 0, code, out + err
      assert_equal "judged", meta(record)["status"]
      assert_equal "learn", meta(record)["current_phase"]
    end
  end

  def test_advances_past_skipped_phase
    with_lifecycle_record(complete: [], current_phase: "intake", status: "intake") do |dir, record|
      record.update_metadata do |m|
        m["risk"] = "medium"
        m["skipped_phases"] = [{ "phase" => "discover", "rationale" => "nothing to discover" }]
      end
      commit_all(dir, "classify")
      complete_phase!(record, "intake", sha: head(dir))
      code, out, err = seal(dir, "intake")
      assert_equal 0, code, out + err
      assert_equal "specify", meta(record)["current_phase"]
    end
  end

  def test_already_sealed_is_idempotent
    with_unsealed("intake", status: "intake") do |dir, _record|
      seal(dir, "intake")
      before = log(dir)
      code, out, err = seal(dir, "intake")
      assert_equal 0, code, out + err
      assert_match(/\Aalready sealed at [0-9a-f]{12}/, out.lines.last)
      assert_equal before, log(dir)
    end
  end

  def test_hook_failure_leaves_rerunnable_state
    with_unsealed("intake", status: "intake") do |dir, record|
      hook = File.join(dir, ".git", "hooks", "pre-commit")
      File.write(hook, "#!/bin/sh\necho 'hook says no' >&2\nexit 1\n")
      File.chmod(0o755, hook)
      before = log(dir)
      code, out, err = seal(dir, "intake")
      assert_equal 2, code, out + err
      assert_includes out + err, "hook says no"
      assert_equal before, log(dir)
      assert_equal "discover", meta(record)["current_phase"], "the metadata write stays so a rerun completes the seal"
      File.delete(hook)
      code, out, err = seal(dir, "intake")
      assert_equal 0, code, out + err
      assert_equal "Record c1 intake", log(dir).first
    end
  end

  def test_refuses_a_phase_other_than_the_sessions_own
    with_unsealed("verify", sealed: %w[intake discover specify threat_model plan implement]) do |dir, _record|
      before = log(dir)
      code, out, err = seal(dir, "verify", env: { "SOFT_FOUNDRY_PHASE" => "implement" })
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "implement"
      assert_includes out + err, "verify"
      assert_equal before, log(dir)
      code, out, err = seal(dir, "verify", env: { "SOFT_FOUNDRY_PHASE" => "verify" })
      assert_equal 0, code, out + err
    end
  end

  def test_refuses_from_a_branch_that_is_not_the_records
    with_unsealed("specify", sealed: %w[intake discover]) do |dir, _record|
      sh(dir, "git", "checkout", "-qb", "other")
      before = log(dir)
      code, out, err = seal(dir, "specify", "--change", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "change/c1"
      assert_includes out + err, "other"
      assert_equal before, log(dir)
    end
  end

  def test_refuses_symlinked_handoff
    with_unsealed("intake", status: "intake") do |dir, record|
      path = record.handoff_path(record.control_plane.phase("intake"))
      File.rename(path, "#{path}.real")
      File.symlink("#{path}.real", path)
      before = log(dir)
      code, out, err = seal(dir, "intake")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code, out + err
      assert_includes out + err, "symlink"
      assert_equal before, log(dir)
    end
  end

  def test_branch_resolved_false_measures_head
    with_unsealed("verify", sealed: %w[intake discover specify threat_model plan implement]) do |dir, record|
      record.update_metadata { |m| m["git"]["branch"] = "change/ghost" }
      commit_all(dir, "point at a branch that does not exist")
      evidence = head(dir)
      record.update_handoff(record.control_plane.phase("verify")) { |h| h["commit_sha"] = evidence }
      code, out, err = seal(dir, "verify", env: { "SOFT_FOUNDRY_PHASE" => "verify" })
      assert_equal 0, code, out + err
      handoff = record.handoff(record.control_plane.phase("verify"))
      assert_equal false, handoff["branch_resolved"]
      sealed = head(dir)
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      commit_all(dir, "later code on the checked-out branch")
      sh(dir, "git", "branch", "change/ghost", sealed)
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("verify")
      current = result.checks.find { |c| c.name == "evidence current" }
      assert_equal :fail, current.outcome, current.detail
      assert_includes current.detail, "STALE"
    end
  end
end
