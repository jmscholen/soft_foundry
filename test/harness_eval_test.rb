# frozen_string_literal: true

require_relative "test_helper"

# changes/factory-readiness: REQ-FR-005 and REQ-FR-006, the executable
# harness evals. A case plants a defective change record (and optionally
# a code change) in a scratch repository carrying this control plane and
# asserts which gate check refuses it; a live case plants a defect and
# runs a fresh-context phase to see whether it is found.
class HarnessEvalTest < Minitest::Test
  include FoundryFixture

  CASES = ".ai/harness-evals/cases"

  # The fixture copies this repository's .ai/, cases included; a test
  # about its own cases starts from an empty case directory.
  def with_cases(cases)
    with_fixture_repo do |dir|
      FileUtils.rm_rf(File.join(dir, CASES))
      FileUtils.mkdir_p(File.join(dir, CASES))
      cases.each { |c| File.write(File.join(dir, CASES, "#{c['id']}.yml"), YAML.dump(c)) }
      yield dir
    end
  end

  def gate_case(id, phase:, outcome:, check: nil, record: {}, repository: nil)
    data = {
      "id" => id, "kind" => "gate", "description" => "planted #{id}",
      "record" => { "risk" => "low", "complete" => %w[intake discover specify threat_model plan implement verify] }.merge(record),
      "expect" => { "phase" => phase, "outcome" => outcome }
    }
    data["expect"]["check"] = check if check
    data["repository"] = repository if repository
    data
  end

  def live_case(id = "live-divide")
    {
      "id" => id, "kind" => "live", "phase" => "review",
      "description" => "a fresh review must notice the planted zero-divisor defect",
      "application" => { "files" => { "${APP_FILE}" => "def divide(a, b) = a / b\n" } },
      "record" => { "risk" => "low", "complete" => %w[intake discover specify threat_model plan implement verify evaluate attack],
                    "files" => { "00-intake/request.md" => "# Intake\n\nREQ-001: divide returns nil when the divisor is zero.\n" } },
      "expect" => { "finding" => "zero|divisor" }
    }
  end

  def eval_cli(dir, *args, runner: nil, env: {})
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil, "SOFT_FOUNDRY_BILLING" => nil }.merge(env)) do
      code = SoftFoundry::CLI.new(["eval", *args], out: out, err: err, root: dir, runner: runner).run
    end
    [code, out.string + err.string]
  end

  def scratch_dirs = Dir.glob(File.join(Dir.tmpdir, "#{SoftFoundry::HarnessEval::TMP_PREFIX}*"))

  # --- gate cases ---------------------------------------------------------------

  def test_a_gate_case_that_holds_passes_with_a_status_line_and_exit_0
    with_cases([gate_case("stale-after-code", phase: "verify", check: "evidence current", outcome: "fail",
                          repository: { "files" => { "${APP_FILE}" => "puts 2\n" } })]) do |dir|
      code, out = eval_cli(dir)
      assert_equal 0, code, out
      assert_includes out, "✓ pass eval stale-after-code: verify evidence current fail, as expected"
      assert_includes out, "✓ pass eval: 1 passed, 0 failed, 0 errors, 0 skipped"
    end
  end

  def test_a_well_formed_control_passes_when_it_expects_the_phase_to_pass
    with_cases([gate_case("control", phase: "verify", outcome: "pass")]) do |dir|
      code, out = eval_cli(dir)
      assert_equal 0, code, out
      assert_includes out, "✓ pass eval control: verify pass, as expected"
    end
  end

  def test_a_case_whose_expectation_does_not_hold_fails_with_exit_2
    with_cases([gate_case("not-stale", phase: "verify", check: "evidence current", outcome: "fail")]) do |dir|
      code, out = eval_cli(dir)
      assert_equal 2, code, out
      assert_includes out, "✗ fail eval not-stale: expected verify evidence current fail, observed pass"
      assert_includes out, "✗ fail eval: 0 passed, 1 failed, 0 errors, 0 skipped"
    end
  end

  def test_planted_handoff_keys_and_later_files_reach_the_gate
    cases = [
      gate_case("unexplained-finding", phase: "review", check: "findings explained", outcome: "fail",
                record: { "complete" => %w[intake discover specify threat_model plan implement verify evaluate attack review],
                          "handoff" => { "review" => { "findings" => [{ "id" => "REV-001", "severity" => "major", "summary" => "planted" }] } } }),
      gate_case("placeholder-left", phase: "verify", check: "no placeholders", outcome: "fail",
                record: { "later_files" => { "06-verification/results.md" => "# Verification Results\n\nTBD\n" } }),
      gate_case("red-is-green", phase: "verify", check: "red evidence", outcome: "fail",
                record: { "files" => { "06-verification/tests.yml" => "commit_sha: ${COMMIT}\nchecks:\n  - id: CHECK-001\n    kind: tests\n    command: x\n    result: pass\n    evidence: evidence/x.log\n    criteria: [AC-001]\n    red_commit: ${COMMIT}\n    test_path: test/app_test.rb\n" } })
    ]
    with_cases(cases) do |dir|
      code, out = eval_cli(dir)
      assert_equal 0, code, out
      assert_includes out, "✓ pass eval: 3 passed"
    end
  end

  def test_an_invalid_case_is_reported_by_check_and_as_an_error_by_eval
    bad = { "id" => "bad", "kind" => "weird", "description" => "", "expect" => { "phase" => "nowhere", "check" => "nonsense", "outcome" => "maybe" },
            "record" => { "files" => { "../escape.txt" => "x" } } }
    with_cases([bad, gate_case("control", phase: "verify", outcome: "pass")]) do |dir|
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.select { |f| f.level == :error }.map(&:message)
      assert messages.any? { |m| m.include?("bad.yml") && m.include?("kind") }, messages.inspect
      assert messages.any? { |m| m.include?("bad.yml") && m.include?("../escape.txt") }, messages.inspect
      code, out = eval_cli(dir)
      assert_equal 2, code, out
      assert_includes out, "✗ error eval bad:"
      assert_includes out, "✓ pass eval control:"
      assert_includes out, "1 passed, 0 failed, 1 error"
    end
  end

  def test_a_case_whose_gate_raises_is_an_error_and_leaves_no_scratch_repository
    broken = gate_case("broken-handoff", phase: "verify", check: "evidence current", outcome: "fail",
                       record: { "later_files" => { "06-verification/handoff.yml" => ": : : not yaml\n  - [\n" } })
    with_cases([broken]) do |dir|
      before = scratch_dirs.size
      code, out = eval_cli(dir)
      assert_equal 2, code, out
      assert_includes out, "✗ error eval broken-handoff:"
      assert_equal before, scratch_dirs.size, "the scratch repository is removed even when the case raises"
    end
  end

  def test_json_carries_the_same_outcomes_as_data
    with_cases([gate_case("control", phase: "verify", outcome: "pass"), live_case]) do |dir|
      code, out = eval_cli(dir, "--json")
      assert_equal 0, code, out
      data = JSON.parse(out)
      assert_equal 1, data["version"]
      assert_equal false, data["stable"]
      assert_equal %w[control live-divide], data["results"].map { |r| r["id"] }
      assert_equal %w[pass skip], data["results"].map { |r| r["outcome"] }
      assert_equal({ "passed" => 1, "failed" => 0, "errors" => 0, "skipped" => 1 }, data["summary"])
    end
  end

  def test_case_filter_runs_only_the_named_cases
    with_cases([gate_case("one", phase: "verify", outcome: "pass"), gate_case("two", phase: "verify", outcome: "pass")]) do |dir|
      code, out = eval_cli(dir, "--case", "two")
      assert_equal 0, code, out
      refute_includes out, "eval one:"
      assert_includes out, "✓ pass eval two:"
      code, out = eval_cli(dir, "--case", "three")
      assert_equal 2, code
      assert_includes out, "✗ error eval three: no such case"
    end
  end

  # --- live cases ----------------------------------------------------------------

  def test_a_live_case_is_skipped_without_live_and_needs_a_shell_with_it
    with_cases([live_case]) do |dir|
      code, out = eval_cli(dir)
      assert_equal 0, code, out
      assert_includes out, "- skip eval live-divide: live case; run `soft-foundry eval --live --shell claude|codex|grok --case live-divide`"
      assert_includes out, "0 passed, 0 failed, 0 errors, 1 skipped"
      code, out = eval_cli(dir, "--live")
      assert_equal 2, code, out
      assert_includes out, "✗ error eval live-divide: --live needs --shell"
    end
  end

  def test_a_live_case_passes_when_the_fresh_session_names_the_planted_defect
    with_cases([live_case]) do |dir|
      launches = []
      fake = lambda do |launch, root|
        launches << launch
        plane = SoftFoundry::ControlPlane.new(root)
        record = SoftFoundry::ChangeRecord.new(root, "eval-live-divide", control_plane: plane)
        complete_phase!(record, "review", sha: head(root))
        phase = plane.phase("review")
        h = record.handoff(phase)
        h["resolved_model"] = { "profile" => "reasoning_high", "provider" => "anthropic", "model" => "fake-1" }
        h["findings"] = [{ "id" => "REV-001", "severity" => "major", "summary" => "divide raises on a zero divisor instead of returning nil",
                           "failure" => "divide(1, 0) raises ZeroDivisionError; REQ-001 says nil" }]
        File.write(record.handoff_path(phase), YAML.dump(h))
        0
      end
      code, out = eval_cli(dir, "--live", "--shell", "claude", runner: fake)
      assert_equal 0, code, out
      assert_equal 1, launches.size
      assert_equal "claude", launches.first.executable
      assert_includes launches.first.prompt, "Phase: review (changes/eval-live-divide/13-review/)"
      assert_includes out, "✓ pass eval live-divide: review on claude (anthropic/fake-1) found REV-001 matching /zero|divisor/"
      assert_equal 0, scratch_dirs.size
    end
  end

  def test_a_live_case_whose_session_misses_or_fails_is_reported
    with_cases([live_case]) do |dir|
      miss = lambda do |_launch, root|
        record = SoftFoundry::ChangeRecord.new(root, "eval-live-divide", control_plane: SoftFoundry::ControlPlane.new(root))
        complete_phase!(record, "review", sha: head(root))
        0
      end
      code, out = eval_cli(dir, "--live", "--shell", "claude", runner: miss)
      assert_equal 2, code, out
      assert_includes out, "✗ fail eval live-divide: review on claude"
      assert_includes out, "no finding matching /zero|divisor/"

      code, out = eval_cli(dir, "--live", "--shell", "claude", runner: ->(_launch, _root) { 3 })
      assert_equal 2, code, out
      assert_includes out, "✗ error eval live-divide: claude exited 3"
    end
  end

  # --- ci and the shipped suite -----------------------------------------------------

  def test_ci_runs_the_gate_cases_and_fails_when_one_fails
    with_cases([gate_case("not-stale", phase: "verify", check: "evidence current", outcome: "fail")]) do |dir|
      code, out = cli(dir, "ci")
      assert_equal 2, code, out
      assert_includes out, "✗ fail eval not-stale:"
      assert_includes out, "✗ ci failed"
    end
    with_cases([gate_case("control", phase: "verify", outcome: "pass"), live_case]) do |dir|
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      assert_includes out, "✓ pass eval control:"
      refute_includes out, "skip eval live-divide", "ci does not list live cases"
    end
  end

  def test_the_shipped_cases_are_well_formed_and_every_gate_case_holds
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    assert_empty SoftFoundry::HarnessEval.lint(REPO_ROOT, plane)
    runner = SoftFoundry::HarnessEval::Runner.new(REPO_ROOT, plane: plane)
    results = runner.run(live: false)
    gate = results.select { |r| r.kind == "gate" }
    assert_operator gate.size, :>=, 10
    assert_equal [], gate.reject { |r| r.outcome == "pass" }.map { |r| "#{r.id}: #{r.detail}" }
    assert_operator gate.count { |r| r.expected == "fail" }, :>=, 9, "at least nine planted defects"
    assert_operator gate.count { |r| r.expected == "pass" }, :>=, 1, "at least one well-formed control"
    assert_operator results.count { |r| r.kind == "live" }, :>=, 1
  end
end
