# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Third remediation pass on changes/gate-hardening: the evaluation's
# findings EVAL-017 (REQ-036: the gate's git cost) and EVAL-018 (REQ-032:
# the lineage failure names a next action).
class RemediationGateHardeningThreeTest < Minitest::Test
  include LifecycleFixture

  # A Git that counts what the gate asks of git.
  class CountingGit < SoftFoundry::Git
    attr_reader :calls

    def run(*args)
      (@calls ||= []) << args
      super
    end
  end

  def test_one_gate_run_reads_head_and_the_repository_once
    with_lifecycle_record(complete: LIFECYCLE, current_phase: "learn") do |dir, record|
      git = CountingGit.new(dir)
      SoftFoundry::Gate.new(record, git: git).evaluate_all
      heads = git.calls.count { |a| a == %w[rev-parse HEAD] }
      repos = git.calls.count { |a| a == %w[rev-parse --is-inside-work-tree] }
      assert_operator heads, :<=, 1, "rev-parse HEAD ran #{heads} times"
      assert_operator repos, :<=, 1, "rev-parse --is-inside-work-tree ran #{repos} times"
    end
  end

  def test_a_later_read_sees_a_commit_made_after_a_gate_run
    with_lifecycle_record(complete: LIFECYCLE.take(5), current_phase: "implement") do |dir, record|
      git = SoftFoundry::Git.new(dir)
      SoftFoundry::Gate.new(record, git: git).evaluate_all
      before = git.head_sha
      File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
      commit_all(dir, "moves HEAD")
      refute_equal before, git.head_sha
    end
  end

  def test_the_lineage_failure_names_a_next_action
    with_lifecycle_record(complete: LIFECYCLE.take(6), current_phase: "verify") do |dir, record|
      first = sh(dir, "git", "rev-list", "--max-parents=0", "HEAD").strip
      complete_phase!(record, "verify", sha: first)
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("verify")
      lineage = result.checks.find { |c| c.name == "commit lineage" }
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, "phase reopen"
    end
  end
end
