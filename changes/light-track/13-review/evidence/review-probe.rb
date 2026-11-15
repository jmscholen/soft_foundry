# frozen_string_literal: true
# Review probe for changes/light-track (13-review). Run from the repository root:
#   env -u SOFT_FOUNDRY_PHASE bundle exec ruby -Ilib -Itest changes/light-track/13-review/evidence/review-probe.rb -v
# It asserts nothing about what the code should do; it prints what it does.
require "lifecycle_fixture"

class ReviewProbe < Minitest::Test
  include LifecycleFixture

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)

  def reopen!(dir, record)
    p = plane(dir)
    SoftFoundry::PhaseReopen.new(dir, plane: p, git: git(dir), record: record).call(p.phase("remediate"), reason: "probe", source: "manual", env: {})
    Array(record.metadata["phase_reopenings"]).last.dig("previous", "remediate")
  end

  # REV-001: a second remediation completed in its handoff but never sealed.
  def test_second_unsealed_remediation
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      p = plane(dir)
      complete_phase!(record, "remediate", sha: head(dir))
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "Record c1 remediate")
      first = reopen!(dir, record)
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "reopen")
      # Round two: the handoff says complete, nothing is sealed or committed.
      complete_phase!(record, "remediate", sha: head(dir))
      second = reopen!(dir, record)
      rules = SoftFoundry::ProcessRules.new(record, git: git(dir))
      puts "PROBE-1 first reopen previous:  #{first.slice('status', 'sealed')}"
      puts "PROBE-1 second reopen previous: #{second.slice('status', 'sealed')} (remediation never sealed in round two)"
      puts "PROBE-1 Record-commits: #{rules.sealed_round_commits}  reopened_rounds: #{rules.reopened_rounds}  remediation_rounds: #{rules.remediation_rounds}  another_round_allowed?: #{rules.another_round_allowed?}"
    end
  end

  # Control: a first remediation completed in its handoff but never sealed.
  def test_first_unsealed_remediation
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      complete_phase!(record, "remediate", sha: head(dir))
      only = reopen!(dir, record)
      rules = SoftFoundry::ProcessRules.new(record, git: git(dir))
      puts "PROBE-2 first unsealed reopen previous: #{only.slice('status', 'sealed')}  remediation_rounds: #{rules.remediation_rounds}"
    end
  end

  # REV-003: file names that hold a glob character.
  def test_paths
    ["app/[id]/page.tsx", "src/routes/[slug].svelte", "docs/what?.md", "LIB/app.rb", "lib\\app.rb", "lib/app.rb/", ".", "lib/.."].each do |path|
      puts "PROBE-3 normalize_path(#{path.inspect}) => #{SoftFoundry::ProcessRules.normalize_path(path).inspect}"
    end
  end
end
