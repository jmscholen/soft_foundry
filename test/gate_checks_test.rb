# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The checks gate hardening adds (REQ-006 to REQ-014, REQ-021): each
# verifies a structural fact the record asserts, fails closed, and skips
# on a closed or released record.
class GateChecksTest < Minitest::Test
  include LifecycleFixture

  THROUGH_PLAN = %w[intake discover specify threat_model plan].freeze
  THROUGH_IMPLEMENT = (THROUGH_PLAN + %w[implement]).freeze
  THROUGH_VERIFY = (THROUGH_IMPLEMENT + %w[verify]).freeze
  THROUGH_ATTACK = (THROUGH_VERIFY + %w[evaluate attack]).freeze
  THROUGH_REVIEW = (THROUGH_ATTACK + %w[review]).freeze

  def gate(dir, record, phase)
    SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate(phase)
  end

  def check(dir, record, phase, name)
    result = gate(dir, record, phase)
    result.checks.find { |c| c.name == name } || flunk("#{phase}: no check named #{name.inspect} in #{result.checks.map(&:name).inspect}")
  end

  def phase_file(record, phase_id, rel)
    File.join(record.phase_dir(record.control_plane.phase(phase_id)), rel)
  end

  def write_phase_file(record, phase_id, rel, text)
    path = phase_file(record, phase_id, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  def load_yaml(path) = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
  def dump_yaml(path, data) = File.write(path, YAML.dump(data))

  def edit_yaml(record, phase_id, rel)
    path = phase_file(record, phase_id, rel)
    data = load_yaml(path)
    yield data
    dump_yaml(path, data)
  end

  def edit_handoff(record, phase_id, &block) = record.update_handoff(record.control_plane.phase(phase_id), &block)

  # --- predecessor recorded (REQ-006) ---

  def test_predecessor_must_be_recorded
    with_lifecycle_record(complete: [], current_phase: "discover") do |dir, record|
      complete_phase!(record, "intake", sha: head(dir))
      complete_phase!(record, "discover", sha: head(dir))
      pred = check(dir, record, "discover", "predecessor complete")
      assert_equal :fail, pred.outcome, pred.detail
      assert_includes pred.detail, "soft-foundry phase seal intake"
      commit_all(dir, "record intake")
      pred = check(dir, record, "discover", "predecessor complete")
      assert_equal :pass, pred.outcome, pred.detail
    end
  end

  def test_predecessor_steps_over_waived_phases
    with_lifecycle_record(complete: [], current_phase: "implement") do |dir, record|
      record.update_metadata do |m|
        m["risk"] = "low"
        m["skipped_phases"] = %w[discover specify threat_model plan].map { |p| { "phase" => p, "rationale" => "low risk" } }
      end
      complete_phase!(record, "intake", sha: head(dir))
      commit_all(dir, "intake sealed")
      complete_phase!(record, "implement", sha: head(dir))
      pred = check(dir, record, "implement", "predecessor complete")
      assert_equal :pass, pred.outcome, pred.detail
      assert_includes pred.detail, "00-intake"
    end
  end

  # --- closed records (REQ-007) ---

  def test_new_checks_skip_on_closed_record
    with_lifecycle_record(complete: LIFECYCLE + %w[learn], current_phase: "done") do |dir, record|
      write_phase_file(record, "specify", "requirements.yml", "requirements:\n  - id: REQ-001\n    statement: fail closed: when it cannot tell\n")
      set_metadata!(record, status: "closed")
      commit_all(dir, "close with a bad file")
      parse = check(dir, record, "specify", "structured files parse")
      assert_equal :skip, parse.outcome, parse.detail
      assert_includes parse.detail, "closed"
      code, out, err = run_cli(dir, "ci")
      assert_equal 0, code, out + err
      assert_includes out, "(closed, skipped)"
    end
  end

  def test_every_new_check_is_explained
    %w[structured\ files\ parse commit\ lineage test\ results\ recorded criteria\ covered evidence\ manifest\ verified verdict\ recorded fresh\ session\ recorded].each do |name|
      assert SoftFoundry::Gate::CHECKS.key?(name), "Gate::CHECKS has no entry for #{name.inspect}"
    end
    with_fixture_repo do |dir|
      code, out = cli(dir, "check")
      assert_equal 0, code, out
    end
  end

  # --- structured files parse (REQ-008) ---

  def test_unparseable_specification_fails_and_cannot_seal
    with_lifecycle_record(complete: %w[intake discover], current_phase: "specify") do |dir, record|
      complete_phase!(record, "specify", sha: head(dir))
      write_phase_file(record, "specify", "requirements.yml", "requirements:\n  - id: REQ-016\n    statement: the gate must fail closed: when it cannot tell\n")
      parse = check(dir, record, "specify", "structured files parse")
      assert_equal :fail, parse.outcome, parse.detail
      assert_includes parse.detail, "02-specification/requirements.yml"
      assert_match(/line \d+/, parse.detail)
      before = sh(dir, "git", "rev-parse", "HEAD")
      code, out, err = run_cli(dir, "phase", "seal", "specify")
      assert_equal 2, code, out + err
      assert_equal before, sh(dir, "git", "rev-parse", "HEAD")
    end
  end

  def test_sequence_manifest_fails_parse
    with_lifecycle_record(complete: THROUGH_IMPLEMENT, current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      write_phase_file(record, "verify", "evidence/manifest.yml", "- path: evidence/x\n  sha256: 00\n")
      parse = check(dir, record, "verify", "structured files parse")
      assert_equal :fail, parse.outcome, parse.detail
      assert_includes parse.detail, "manifest.yml"
      assert_includes parse.detail, "mapping"
    end
  end

  # --- commit lineage (REQ-009) ---

  def test_lineage_fails_on_older_commit
    with_lifecycle_record(complete: %w[intake], current_phase: "discover") do |dir, record|
      parent = sh(dir, "git", "rev-parse", "HEAD~1").strip
      complete_phase!(record, "discover", sha: parent)
      lineage = check(dir, record, "discover", "commit lineage")
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, parent[0, 12]
      assert_includes lineage.detail, "ancestor"
    end
  end

  def test_lineage_fails_on_unreachable_commit
    with_lifecycle_record(complete: THROUGH_IMPLEMENT, current_phase: "verify") do |dir, record|
      sh(dir, "git", "checkout", "-qb", "elsewhere")
      File.write(File.join(dir, "lib", "app.rb"), "puts 9\n")
      commit_all(dir, "unrelated")
      stray = head(dir)
      sh(dir, "git", "checkout", "-q", "change/c1")
      complete_phase!(record, "verify", sha: stray)
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :fail, lineage.outcome, lineage.detail
      assert_includes lineage.detail, "not an ancestor"
    end
  end

  def test_lineage_measures_stacked_record_on_its_branch
    with_lifecycle_record(complete: THROUGH_VERIFY, current_phase: "evaluate") do |dir, record|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "c2 code on top of c1")
      lineage = check(dir, record, "verify", "commit lineage")
      assert_equal :pass, lineage.outcome, lineage.detail
      current = check(dir, record, "verify", "evidence current")
      assert_equal :pass, current.outcome, current.detail
    end
  end

  # --- test results recorded (REQ-010) ---

  def with_verify_tests(result:, criteria: ["AC-001"])
    with_lifecycle_record(complete: THROUGH_IMPLEMENT, current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "tests.yml") do |t|
        t["checks"] << { "id" => "CHECK-002", "kind" => "tests", "command" => "ruby -e 1", "result" => result, "evidence" => "evidence/recorded.txt", "criteria" => criteria }
      end
      yield dir, record
    end
  end

  def test_unacknowledged_fail_result_fails
    with_verify_tests(result: "fail") do |dir, record|
      results = check(dir, record, "verify", "test results recorded")
      assert_equal :fail, results.outcome, results.detail
      assert_includes results.detail, "CHECK-002"
    end
  end

  def test_fail_result_named_in_finding_passes
    with_verify_tests(result: "fail") do |dir, record|
      edit_handoff(record, "verify") { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "major", "summary" => "CHECK-002 fails on the inherited variable" }] }
      results = check(dir, record, "verify", "test results recorded")
      assert_equal :pass, results.outcome, results.detail
      assert_includes results.detail, "CHECK-002"
    end
  end

  def test_skipped_with_criteria_must_be_named
    with_verify_tests(result: "skipped") do |dir, record|
      results = check(dir, record, "verify", "test results recorded")
      assert_equal :fail, results.outcome, results.detail
      assert_includes results.detail, "CHECK-002"
    end
  end

  # --- criteria covered (REQ-011) ---

  def with_three_criteria
    with_lifecycle_record(complete: %w[intake discover], current_phase: "specify") do |dir, record|
      complete_phase!(record, "specify", sha: head(dir))
      edit_yaml(record, "specify", "acceptance-criteria.yml") do |a|
        a["criteria"] = %w[AC-001 AC-002 AC-003].map { |id| { "id" => id, "requirements" => ["REQ-001"], "given" => "g", "when" => "w", "then" => "t", "verified_by" => [] } }
      end
      commit_all(dir, "specification")
      %w[threat_model plan implement].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "through implement")
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "tests.yml") { |t| t["checks"].first["criteria"] = %w[AC-001 AC-002] }
      commit_all(dir, "verify")
      yield dir, record
    end
  end

  def test_uncovered_criteria_warn_at_verify
    with_three_criteria do |dir, record|
      covered = check(dir, record, "verify", "criteria covered")
      assert_equal :warn, covered.outcome, covered.detail
      assert_includes covered.detail, "AC-003"
      refute gate(dir, record, "verify").failed?
    end
  end

  def test_uncovered_criteria_fail_at_judge
    with_three_criteria do |dir, record|
      %w[evaluate attack review judge].each { |id| complete_phase!(record, id, sha: head(dir)) }
      edit_yaml(record, "evaluate", "journeys.yml") { |j| j["journeys"].first["criteria"] = [] }
      commit_all(dir, "through judge")
      covered = check(dir, record, "judge", "criteria covered")
      assert_equal :fail, covered.outcome, covered.detail
      assert_includes covered.detail, "AC-003"
    end
  end

  def test_criteria_set_aside_with_reason_pass_and_blank_reason_fails
    with_three_criteria do |dir, record|
      %w[evaluate attack review judge].each { |id| complete_phase!(record, id, sha: head(dir)) }
      edit_yaml(record, "evaluate", "journeys.yml") { |j| j["journeys"].first["criteria"] = [] }
      edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-003", "reason" => "needs a production observation; carried as GOLIVE-1" }] }
      commit_all(dir, "through judge")
      covered = check(dir, record, "judge", "criteria covered")
      assert_equal :pass, covered.outcome, covered.detail
      assert_includes covered.detail, "AC-003"
      edit_yaml(record, "judge", "evidence.yml") { |e| e["criteria_not_covered"] = [{ "id" => "AC-003", "reason" => "   " }] }
      covered = check(dir, record, "judge", "criteria covered")
      assert_equal :fail, covered.outcome, covered.detail
    end
  end

  # --- evidence manifest verified (REQ-012, REQ-034) ---

  def test_manifest_digest_mismatch_fails
    with_lifecycle_record(complete: THROUGH_IMPLEMENT, current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      File.write(phase_file(record, "verify", "evidence/recorded.txt"), "changed after hashing\n")
      manifest = check(dir, record, "verify", "evidence manifest verified")
      assert_equal :fail, manifest.outcome, manifest.detail
      assert_includes manifest.detail, "evidence/recorded.txt"
      assert_match(/[0-9a-f]{12}.*[0-9a-f]{12}/, manifest.detail)
    end
  end

  def test_unlisted_evidence_file_warns
    with_lifecycle_record(complete: THROUGH_VERIFY + %w[evaluate], current_phase: "attack") do |dir, record|
      complete_phase!(record, "attack", sha: head(dir))
      File.write(phase_file(record, "attack", "evidence/extra.txt"), "unlisted\n")
      manifest = check(dir, record, "attack", "evidence manifest verified")
      assert_equal :warn, manifest.outcome, manifest.detail
      assert_includes manifest.detail, "evidence/extra.txt"
      refute gate(dir, record, "attack").failed?
    end
  end

  def test_manifest_path_outside_phase_fails
    with_lifecycle_record(complete: THROUGH_IMPLEMENT, current_phase: "verify") do |dir, record|
      complete_phase!(record, "verify", sha: head(dir))
      edit_yaml(record, "verify", "evidence/manifest.yml") { |m| m["artifacts"] = [{ "path" => "../../05-implementation/log.md", "produced_by" => "CHECK-001", "sha256" => "0" * 64 }] }
      manifest = check(dir, record, "verify", "evidence manifest verified")
      assert_equal :fail, manifest.outcome, manifest.detail
      assert_includes manifest.detail, "outside"
    end
  end

  # --- verdict recorded (REQ-013) ---

  def test_verdict_blocked_is_recorded
    with_lifecycle_record(complete: LIFECYCLE, current_phase: "learn") do |dir, record|
      final = phase_file(record, "judge", "final.md")
      File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nBLOCKED"))
      verdict = check(dir, record, "judge", "verdict recorded")
      assert_equal :pass, verdict.outcome, verdict.detail
      assert_equal "BLOCKED", verdict.detail
    end
  end

  def test_unfilled_verdict_fails
    with_lifecycle_record(complete: LIFECYCLE, current_phase: "learn") do |dir, record|
      final = phase_file(record, "judge", "final.md")
      File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED | APPROVED_WITH_RESIDUAL_RISK | BLOCKED | REJECTED"))
      verdict = check(dir, record, "judge", "verdict recorded")
      assert_equal :fail, verdict.outcome, verdict.detail
      %w[APPROVED BLOCKED REJECTED].each { |w| assert_includes verdict.detail, w }
    end
  end

  # --- fresh session recorded (REQ-014) ---

  def set_mode!(dir, mode)
    path = File.join(dir, ".ai", "policies", "enforcement.yml")
    File.write(path, File.read(path).sub(/^  mode: \w+/, "  mode: #{mode}"))
    commit_all(dir, "mode #{mode}")
  end

  def test_fresh_session_required_in_block_mode
    with_lifecycle_record(complete: THROUGH_ATTACK, current_phase: "review") do |dir, record|
      set_mode!(dir, "block")
      complete_phase!(record, "review", sha: head(dir), runner: false)
      fresh = check(dir, record, "review", "fresh session recorded")
      assert_equal :fail, fresh.outcome, fresh.detail
      assert_includes fresh.detail, "soft-foundry phase run review"
    end
  end

  def test_fresh_session_skips_in_warn_mode
    with_lifecycle_record(complete: THROUGH_ATTACK, current_phase: "review") do |dir, record|
      set_mode!(dir, "warn")
      complete_phase!(record, "review", sha: head(dir), runner: false)
      fresh = check(dir, record, "review", "fresh session recorded")
      assert_equal :skip, fresh.outcome, fresh.detail
      code, out, = run_cli(dir, "gate", "review")
      assert_equal 0, code
      assert_includes out, "without `soft-foundry phase run`"
    end
  end

  def test_fresh_session_ignores_machine_override
    with_lifecycle_record(complete: THROUGH_REVIEW, current_phase: "judge") do |dir, record|
      set_mode!(dir, "block")
      FileUtils.mkdir_p(File.join(dir, ".soft-foundry"))
      File.write(File.join(dir, ".soft-foundry", "enforcement.yml"), "guard:\n  mode: off\n")
      complete_phase!(record, "judge", sha: head(dir), runner: true)
      fresh = check(dir, record, "judge", "fresh session recorded")
      assert_equal :pass, fresh.outcome, fresh.detail
      complete_phase!(record, "judge", sha: head(dir), runner: false)
      fresh = check(dir, record, "judge", "fresh session recorded")
      assert_equal :fail, fresh.outcome, "the machine-local override must not relax the gate"
    end
  end

  # --- fail closed (REQ-021) ---

  def test_git_string_is_a_gate_line
    with_lifecycle_record(complete: THROUGH_VERIFY, current_phase: "evaluate") do |dir, record|
      path = File.join(record.dir, "metadata.yml")
      File.write(path, File.read(path).sub(/^git:\n(?:  .*\n)+/, "git: a string\n"))
      code, out, err = run_cli(dir, "gate", "verify")
      assert_equal 2, code, out + err
      assert_includes out, "metadata.yml"
      assert_includes out, "git"
      assert_includes out, "mapping"
      refute_includes out + err, "does not have #dig"
      refute_match(/\.rb:\d+:in/, out + err)
    end
  end
end
