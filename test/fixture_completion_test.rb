# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The one phase-completion fixture (HarnessEval.complete_phase!, which
# test_helper's complete_phase! delegates to) writes what the hardened
# gate accepts: a record it completes passes every check through judge,
# and a harness-eval case that plants a complete record is recorded.
class FixtureCompletionTest < Minitest::Test
  include LifecycleFixture

  ALL = (LIFECYCLE + %w[learn]).freeze

  def test_completed_record_passes_every_gate
    with_lifecycle_record(complete: ALL, current_phase: "done") do |dir, record|
      results = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate_all
      failing = results.flat_map { |r| r.checks.select { |c| c.outcome == :fail }.map { |c| "#{r.phase.id}: #{c.name}: #{c.detail}" } }
      assert_empty failing
      names = results.find { |r| r.phase.id == "verify" }.checks.map(&:name)
      %w[structured\ files\ parse commit\ lineage test\ results\ recorded criteria\ covered evidence\ manifest\ verified].each { |n| assert_includes names, n }
      judge = results.find { |r| r.phase.id == "judge" }.checks
      assert_equal "APPROVED", judge.find { |c| c.name == "verdict recorded" }.detail
      assert_equal :pass, judge.find { |c| c.name == "fresh session recorded" }.outcome
    end
  end

  def test_fixture_is_shared_between_tests_and_harness_evals
    assert_respond_to SoftFoundry::HarnessEval, :complete_phase!
    with_lifecycle_record(complete: [], current_phase: "verify") do |dir, record|
      %w[intake discover specify threat_model plan implement].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "through implement")
      SoftFoundry::HarnessEval.complete_phase!(record, record.control_plane.phase("verify"), head(dir))
      tests = YAML.safe_load_file(File.join(record.phase_dir(record.control_plane.phase("verify")), "tests.yml"))
      assert_equal "pass", tests["checks"].first["result"]
      manifest = YAML.safe_load_file(File.join(record.phase_dir(record.control_plane.phase("verify")), "evidence", "manifest.yml"))
      artifact = manifest["artifacts"].first
      assert File.file?(File.join(record.phase_dir(record.control_plane.phase("verify")), artifact["path"]))
      assert_equal Digest::SHA256.file(File.join(record.phase_dir(record.control_plane.phase("verify")), artifact["path"])).hexdigest, artifact["sha256"]
    end
  end

  def test_runner_false_leaves_executed_by_alone
    with_lifecycle_record(complete: [], current_phase: "review") do |dir, record|
      complete_phase!(record, "review", sha: head(dir), runner: false)
      assert_nil record.handoff(record.control_plane.phase("review"))["executed_by"]
      complete_phase!(record, "review", sha: head(dir), runner: true)
      assert_equal true, record.handoff(record.control_plane.phase("review")).dig("executed_by", "fresh_context")
    end
  end
end
