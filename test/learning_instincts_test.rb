# frozen_string_literal: true

require_relative "test_helper"

# Instincts: the learning phase's output as one-line triggers with an
# action, a confidence score, and evidence. The gate validates them,
# `learn list` shows them across records, and `learn promote` copies those
# above the threshold into .ai/rules/learned.md, only through a change
# record on a change branch.
class LearningInstinctsTest < Minitest::Test
  include FoundryFixture

  INSTINCTS = [
    { "id" => "commit-the-failing-test-first", "trigger" => "when starting a feature or fix", "action" => "commit the failing test alone before any implementation and name that commit as red_commit",
      "confidence" => 0.9, "domain" => "testing", "evidence" => [{ "finding" => "REV-020" }] },
    { "id" => "prefer-checkout-exe-in-hooks", "trigger" => "when a hook runs a tool that is also the repository under development", "action" => "prefer the checkout's executable over one on PATH",
      "confidence" => 0.6, "domain" => "git", "evidence" => [{ "phase" => "05-implementation" }] }
  ].freeze

  def write_instincts!(record, plane, instincts)
    path = File.join(record.phase_dir(plane.phase("learn")), "instincts.yml")
    File.write(path, YAML.dump("instincts" => instincts))
  end

  # A change on its own branch with every required phase complete through
  # learning, so the learning gate is what is under test.
  def with_learned_change(slug = "c1", instincts: INSTINCTS)
    with_fixture_repo do |dir|
      # The fixture copies this repository's .ai/, whose learned.md
      # accumulates real promotions; these tests need an empty ledger.
      File.write(File.join(dir, ".ai/rules/learned.md"), SoftFoundry::Learning::HEADER)
      sh(dir, "git", "commit", "-qam", "empty learned rules")
      plane = SoftFoundry::ControlPlane.new(dir)
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane)
      commit_all(dir, "record")
      %w[intake discover specify threat_model plan implement verify evaluate attack review judge learn].each { |id| complete_phase!(record, id, sha: head(dir)) }
      write_instincts!(record, plane, instincts)
      yield dir, plane, record
    end
  end

  def learn_check(dir, record)
    SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("learn").checks.find { |c| c.name == "instincts valid" }
  end

  # --- template and gate --------------------------------------------------------

  def test_change_new_scaffolds_an_empty_instincts_file_and_the_gate_accepts_it
    with_learned_change(instincts: []) do |dir, plane, record|
      path = File.join(record.phase_dir(plane.phase("learn")), "instincts.yml")
      assert File.file?(path)
      check = learn_check(dir, record)
      assert_equal :pass, check.outcome, check.detail
      assert_includes check.detail, "no instincts recorded"
      assert_includes plane.skill("learning").required_files, "instincts.yml"
    end
  end

  def test_valid_instincts_pass_and_are_counted
    with_learned_change do |dir, _plane, record|
      check = learn_check(dir, record)
      assert_equal :pass, check.outcome, check.detail
      assert_includes check.detail, "2 instincts"
    end
  end

  def test_invalid_instincts_fail_with_the_reason
    bad = [
      [INSTINCTS.first.merge("confidence" => 1.5), "confidence"],
      [INSTINCTS.first.merge("action" => ""), "action"],
      [INSTINCTS.first.merge("id" => "Not Kebab"), "id"],
      [INSTINCTS.first.merge("evidence" => []), "evidence"]
    ]
    bad.each do |instinct, word|
      with_learned_change(instincts: [instinct]) do |dir, _plane, record|
        check = learn_check(dir, record)
        assert_equal :fail, check.outcome, "#{word}: #{check.detail}"
        assert_includes check.detail, word
      end
    end
    with_learned_change(instincts: [INSTINCTS.first, INSTINCTS.first]) do |dir, _plane, record|
      check = learn_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "duplicate"
    end
  end

  # --- learn list ----------------------------------------------------------------

  def test_learn_list_shows_instincts_across_records_by_confidence
    with_learned_change do |dir, plane, _record|
      commit_all(dir, "c1 learned")
      sh(dir, "git", "checkout", "-qb", "change/c2")
      cli(dir, "change", "new", "c2")
      c2 = SoftFoundry::ChangeRecord.new(dir, "c2", control_plane: plane)
      write_instincts!(c2, plane, [INSTINCTS.first.merge("id" => "read-the-guard-log", "confidence" => 0.75)])
      code, out = cli(dir, "learn", "list")
      assert_equal 0, code, out
      lines = out.lines.map(&:strip).grep(/\A\d\.\d\d /)
      assert_equal ["0.90 c1 commit-the-failing-test-first", "0.75 c2 read-the-guard-log", "0.60 c1 prefer-checkout-exe-in-hooks"], lines.map { |l| l.split(/\s+/).first(3).join(" ") }
      code, out = cli(dir, "learn", "list", "--min-confidence", "0.8")
      assert_equal 0, code, out
      assert_includes out, "commit-the-failing-test-first"
      refute_includes out, "read-the-guard-log"
    end
  end

  # --- learn promote -----------------------------------------------------------------

  def test_promote_refuses_outside_a_change_record
    with_learned_change do |dir, _plane, _record|
      commit_all(dir, "c1 learned")
      sh(dir, "git", "checkout", "-q", "main")
      code, out = cli(dir, "learn", "promote")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "no change record for branch 'main'"
      refute File.exist?(File.join(dir, ".ai/rules/learned.md")) && File.read(File.join(dir, ".ai/rules/learned.md")).include?("commit-the-failing-test-first")
    end
  end

  def test_promote_writes_learned_rules_with_provenance_above_the_threshold_and_is_idempotent
    with_learned_change do |dir, plane, _record|
      commit_all(dir, "c1 learned")
      sh(dir, "git", "checkout", "-qb", "change/promote-1")
      cli(dir, "change", "new", "promote-1")
      code, out = cli(dir, "learn", "promote")
      assert_equal 0, code, out
      assert_includes out, "✓ pass promoted commit-the-failing-test-first (0.90, from c1)"
      assert_includes out, "- skip prefer-checkout-exe-in-hooks: confidence 0.60 is below 0.80"
      learned = File.read(File.join(dir, ".ai/rules/learned.md"))
      assert_includes learned, "## commit-the-failing-test-first"
      assert_includes learned, "when starting a feature or fix"
      assert_includes learned, "from change c1"
      assert_includes learned, "REV-020"
      refute_includes learned, "prefer-checkout-exe-in-hooks"

      code, out = cli(dir, "learn", "promote")
      assert_equal 0, code, out
      assert_includes out, "- skip commit-the-failing-test-first: already in .ai/rules/learned.md"
      assert_equal 1, File.read(File.join(dir, ".ai/rules/learned.md")).scan("## commit-the-failing-test-first").size

      code, out = cli(dir, "learn", "promote", "--min-confidence", "0.5")
      assert_equal 0, code, out
      assert_includes out, "✓ pass promoted prefer-checkout-exe-in-hooks (0.60, from c1)"
      assert_includes File.read(File.join(dir, ".ai/rules/learned.md")), "## prefer-checkout-exe-in-hooks"
      assert_equal plane.phase("learn").id, "learn"
    end
  end

  def test_promote_dry_run_writes_nothing
    with_learned_change do |dir, _plane, _record|
      commit_all(dir, "c1 learned")
      sh(dir, "git", "checkout", "-qb", "change/promote-1")
      cli(dir, "change", "new", "promote-1")
      before = File.read(File.join(dir, ".ai/rules/learned.md"))
      code, out = cli(dir, "learn", "promote", "--dry-run")
      assert_equal 0, code, out
      assert_includes out, "would promote commit-the-failing-test-first"
      assert_equal before, File.read(File.join(dir, ".ai/rules/learned.md"))
    end
  end

  def test_threshold_comes_from_the_learning_policy
    with_fixture_repo do |dir|
      assert_equal 0.8, SoftFoundry::Learning.min_confidence(dir)
      File.write(File.join(dir, ".ai/policies/learning.yml"), YAML.dump("version" => 1, "promote" => { "min_confidence" => 0.95 }))
      assert_equal 0.95, SoftFoundry::Learning.min_confidence(dir)
    end
  end

  def test_learned_rules_file_exists_and_is_a_baseline_rule_for_implementation
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    assert File.file?(File.join(REPO_ROOT, ".ai/rules/learned.md"))
    assert_includes Array(plane.skill("implementation").definition.dig("rules", "baseline")), ".ai/rules/learned.md"
    assert_includes Array(plane.skill("exploration").definition.dig("rules", "baseline")), ".ai/rules/learned.md"
  end
end
