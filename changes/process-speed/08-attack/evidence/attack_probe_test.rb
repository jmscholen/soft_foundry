# frozen_string_literal: true

# Attack probes for changes/process-speed (08-attack). Each test builds a
# throwaway fixture repository in a temp directory (test/lifecycle_fixture.rb),
# attempts one violation of the convergence rules, prints what it observed
# and asserts the safe behaviour. A failing assertion is a violation.
#
# Run from the repository root:
#   ruby -Ilib -Itest changes/process-speed/08-attack/evidence/attack_probe_test.rb -v
#
# Nothing here touches the real repository: every write is inside the
# fixture's temp directory.

require_relative "../../../../test/lifecycle_fixture"

class ProcessSpeedAttackProbe < Minitest::Test
  include FinishedFixture

  def new_rules!(record, risk: nil)
    record.update_metadata do |m|
      m["rules"] = 2
      m["risk"] = risk if risk
    end
  end

  def commit_any!(dir, msg)
    sh(dir, "git", "add", "-A")
    sh(dir, "git", "commit", "-q", "--allow-empty", "-m", msg)
  end

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)

  def reopen(dir, record, phase_id, docs_only: false)
    p = plane(dir)
    SoftFoundry::PhaseReopen.new(dir, plane: p, git: git(dir), record: record)
                            .call(p.phase(phase_id), reason: "attack probe", env: {}, docs_only: docs_only)
  end

  def seal(dir, record, phase_id)
    p = plane(dir)
    SoftFoundry::PhaseSeal.new(dir, plane: p, git: git(dir), record: record, env: {}).call(p.phase(phase_id))
  end

  def gate(dir, record, phase_id) = SoftFoundry::Gate.new(record, git: git(dir)).evaluate(plane(dir).phase(phase_id))
  def check(result, name) = result.checks.find { |c| c.name == name }

  def sealed_rounds!(dir, record, rounds)
    rounds.times do |i|
      @round_file = (@round_file || 0) + 1
      File.write(File.join(record.dir, "09-remediation", "round-#{@round_file}.md"), "round #{@round_file}\n")
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "Record #{record.slug} remediate")
    end
  end

  def criteria!(record, entries)
    path = File.join(record.dir, "02-specification", "acceptance-criteria.yml")
    data = { "criteria" => entries.map { |id, tier| { "id" => id, "tier" => tier, "requirements" => ["REQ-001"], "given" => "g", "when" => "w", "then" => "t", "verified_by" => [] } } }
    File.write(path, YAML.dump(data))
  end

  def decide!(record, entry)
    record.update_metadata { |m| m["human_decisions"] = Array(m["human_decisions"]) + [entry] }
  end

  def observe(id, text) = puts("\n[#{id}] #{text}")

  # ATTACK-001 / THREAT-001: an open session writes a must-criteria approval
  # into metadata.yml itself and seals specify.
  def test_attack_001_fabricated_approval_is_named_at_seal
    with_lifecycle_record(complete: %w[intake discover], current_phase: "specify") do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"], ["AC-002", "should"]])
      commit_any!(dir, "criteria")
      complete_phase!(record, "specify", sha: head(dir))
      decide!(record, { "boundary" => "must criteria approval", "criteria" => ["AC-001"], "decided_by" => "maintainer", "decided_at" => "2026-11-14", "decision" => "approved" })
      result = seal(dir, record, "specify")
      observe("ATTACK-001", "seal outcome=#{result.outcome}; lines=#{result.lines.inspect}")
      assert_includes result.lines.join("\n"), "human_decisions", "the seal must name the hand-edited human_decisions"
    end
  end

  # ATTACK-002 / THREAT-002: lower the round count without rewriting history
  # by pointing metadata git.branch at another existing branch (main), so
  # the seal commits are counted from a tip that does not contain them.
  def test_attack_002_round_count_via_git_branch_redirect
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      before = SoftFoundry::ProcessRules.new(record, git: git(dir)).remediation_rounds
      text = File.read(File.join(record.dir, "metadata.yml"))
      File.write(File.join(record.dir, "metadata.yml"), text.sub(/^  branch: .*$/, "  branch: main"))
      after = SoftFoundry::ProcessRules.new(record, git: git(dir)).remediation_rounds
      outcome = begin
        reopen(dir, record, "remediate")
        "reopen PERMITTED (third round started with no decision)"
      rescue SoftFoundry::TargetError => e
        "reopen refused: #{e.message[0, 120]}"
      end
      observe("ATTACK-002", "git.branch=#{record.git_branch}; rounds before=#{before} after=#{after}; #{outcome}")
      assert_equal before, after, "editing git.branch must not lower the sealed round count"
    end
  end

  # ATTACK-002b: the same redirect after a third round is sealed by hand:
  # does the review gate still fail the cap?
  def test_attack_002b_review_gate_after_branch_redirect
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 3)
      text = File.read(File.join(record.dir, "metadata.yml"))
      File.write(File.join(record.dir, "metadata.yml"), text.sub(/^  branch: .*$/, "  branch: main"))
      r = gate(dir, record, "review")
      cap = check(r, "remediation within cap")
      failing = r.checks.reject { |c| %i[pass skip warn].include?(c.outcome) }.map { |c| "#{c.name}=#{c.outcome}: #{c.detail.to_s[0, 140]}" }
      observe("ATTACK-002b", "cap=#{cap.outcome} (#{cap.detail}); other non-passing: #{failing.inspect}")
      assert_equal :fail, cap.outcome, "the review cap check must fail at 3 rounds without a decision"
    end
  end

  # ATTACK-003 / THREAT-002: a third remediation reached without a reopen.
  def test_attack_003_third_round_without_reopen
    with_lifecycle_record(complete: LIFECYCLE - %w[review judge], current_phase: "remediate") do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      commit_any!(dir, "rules")
      complete_phase!(record, "remediate", sha: head(dir))
      result = seal(dir, record, "remediate")
      observe("ATTACK-003", "seal outcome=#{result.outcome}; status=#{record.metadata['status']}")
      assert_equal :refused, result.outcome
    end
  end

  # ATTACK-004 / THREAT-003: leave awaiting_human by hand without a decision.
  def test_attack_004_status_edited_back_without_decision
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 3)
      record.update_metadata { |m| m["status"] = "in_progress" }
      outs = %w[review judge].map { |id| "#{id}=#{check(gate(dir, record, id), 'remediation within cap').outcome}" }
      reopen_out = begin
        reopen(dir, record, "remediate")
        "reopen PERMITTED"
      rescue SoftFoundry::TargetError
        "reopen refused; status=#{record.metadata['status']}"
      end
      observe("ATTACK-004", "#{outs.join(', ')}; #{reopen_out}")
      assert_equal %w[review=fail judge=fail], outs
      assert_includes reopen_out, "refused"
    end
  end

  # ATTACK-005 / THREAT-004: under a documentation-only reopen, change the
  # control plane, AGENTS.md (the agent bootstrap contract), and an
  # uncommitted lib/ file, then seal remediation.
  def docs_only_setup(dir, record)
    new_rules!(record)
    sealed_rounds!(dir, record, 1)
    commit_any!(dir, "rules")
    reopen(dir, record, "remediate", docs_only: true)
    commit_any!(dir, "reopened")
  end

  def test_attack_005a_control_plane_under_docs_only
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      File.write(File.join(dir, ".ai", "workflow.yml"), File.read(File.join(dir, ".ai", "workflow.yml")) + "\n# edited\n")
      commit_all(dir, "edit control plane")
      complete_phase!(record, "remediate", sha: head(dir))
      result = seal(dir, record, "remediate")
      observe("ATTACK-005a", "seal outcome=#{result.outcome}; #{result.lines.join(' ')[0, 200]}")
      assert_equal :refused, result.outcome
    end
  end

  def test_attack_005b_uncommitted_code_under_docs_only
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      complete_phase!(record, "remediate", sha: head(dir))
      File.write(File.join(dir, "lib", "app.rb"), "puts 'uncommitted'\n")
      result = seal(dir, record, "remediate")
      observe("ATTACK-005b", "seal outcome=#{result.outcome}; #{result.lines.join(' ')[0, 200]}")
      assert_equal :refused, result.outcome
    end
  end

  def test_attack_005c_agents_md_under_docs_only
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      File.write(File.join(dir, "AGENTS.md"), "# agents\n\nA changed contract line.\n")
      commit_all(dir, "edit agent contract")
      complete_phase!(record, "remediate", sha: head(dir))
      result = seal(dir, record, "remediate")
      observe("ATTACK-005c", "seal outcome=#{result.outcome}; AGENTS.md classified documentation=#{SoftFoundry::ProcessRules.documentation_path?(plane(dir), 'AGENTS.md', 'c1')}")
      refute_equal :refused, result.outcome, "per REQ-011 top-level Markdown is documentation; recorded to show the consequence"
    end
  end

  # ATTACK-005d: code committed after a documentation-only seal: verify must go stale.
  def test_attack_005d_code_after_docs_only_seal_stales_verify
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      File.write(File.join(dir, "README.md"), "# wording\n")
      commit_all(dir, "wording")
      complete_phase!(record, "remediate", sha: head(dir))
      sealed = seal(dir, record, "remediate")
      File.write(File.join(dir, "lib", "app.rb"), "puts 'after seal'\n")
      commit_all(dir, "code after docs-only seal")
      v = check(gate(dir, record, "verify"), "evidence current")
      observe("ATTACK-005d", "docs-only seal=#{sealed.outcome}; verify evidence current=#{v.outcome} (#{v.detail.to_s[0, 140]})")
      refute_equal :pass, v.outcome
    end
  end

  # ATTACK-005e: the documentation-only refusal says "reopen remediate
  # without --docs-only". Does that way out exist?
  def test_attack_005e_docs_only_refusal_has_a_way_out
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      File.write(File.join(dir, "lib", "app.rb"), "puts 'real fix'\n")
      commit_all(dir, "code fix")
      complete_phase!(record, "remediate", sha: head(dir))
      refused = seal(dir, record, "remediate")
      record.update_handoff(plane(dir).phase("remediate")) { |h| h["status"] = "pending" }
      follow = begin
        r = reopen(dir, record, "remediate")
        "reopen permitted, reset=#{r.reset.map(&:id).inspect}"
      rescue SoftFoundry::TargetError => e
        "reopen refused: #{e.message[0, 160]}"
      end
      via_verify = begin
        r = reopen(dir, record, "verify")
        "reopen verify reset=#{r.reset.map(&:id).inspect}"
      rescue SoftFoundry::TargetError => e
        "reopen verify refused: #{e.message[0, 160]}"
      end
      complete_phase!(record, "remediate", sha: head(dir))
      after = seal(dir, record, "remediate")
      observe("ATTACK-005e", "first seal=#{refused.outcome}; advised `phase reopen remediate`: #{follow}; #{via_verify}; seal after that=#{after.outcome}: #{after.lines.join(' ')[0, 160]}")
      refute_equal :refused, after.outcome, "after following the refusal's advice, a non-documentation remediation must be sealable"
    end
  end

  # ATTACK-006 / THREAT-005: demote an approved must after specify is sealed.
  def test_attack_006_demote_must_after_specify_seal
    with_lifecycle_record(complete: %w[intake discover], current_phase: "specify") do |dir, record|
      new_rules!(record, risk: "high")
      criteria!(record, [["AC-001", "must"], ["AC-002", "must"]])
      decide!(record, { "boundary" => "must criteria approval", "criteria" => %w[AC-001 AC-002], "decided_by" => "maintainer", "decided_at" => "2026-11-14", "decision" => "approved" })
      commit_any!(dir, "criteria")
      complete_phase!(record, "specify", sha: head(dir))
      sealed = seal(dir, record, "specify")
      criteria!(record, [["AC-001", "must"], ["AC-002", "should"]])
      record.update_metadata { |m| m["human_decisions"].last["criteria"] = ["AC-001"] }
      r = gate(dir, record, "specify")
      lock = check(r, "specification locked")
      observe("ATTACK-006", "seal=#{sealed.outcome}; specification locked=#{lock.outcome} (#{lock.detail.to_s[0, 120]}); approved=#{check(r, 'must criteria approved').outcome}")
      assert_equal :fail, lock.outcome
    end
  end

  # ATTACK-007 / THREAT-006: mark a finding about a modified file
  # outside_change, naming the file in a form the string comparison misses.
  def test_attack_007_outside_change_path_spelling
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record)
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "change app")
      results = ["lib/app.rb", "./lib/app.rb", "lib/app.rb ", "lib/*.rb", "lib//app.rb", "LIB/app.rb", "lib/"].to_h do |spelling|
        record.update_handoff(record.control_plane.phase("review")) do |h|
          h["findings"] = [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "x", "paths" => [spelling] }]
        end
        [spelling, check(gate(dir, record, "review"), "outside-change findings").outcome]
      end
      observe("ATTACK-007", results.inspect)
      passed = results.select { |_, o| o == :pass }.keys
      assert_empty passed, "a spelling of the modified path lib/app.rb passed the outside-change check: #{passed.inspect}"
    end
  end

  # ATTACK-008 / THREAT-007: drop the rules version after the intake seal,
  # then try the cap at the points that enforce it (reopen, remediation
  # seal, review and judge gates).
  def test_attack_008a_rules_dropped_after_intake_disarms_cap
    with_lifecycle_record(complete: [], current_phase: "intake") do |dir, record|
      new_rules!(record)
      commit_any!(dir, "rules")
      complete_phase!(record, "intake", sha: head(dir))
      intake_seal = seal(dir, record, "intake")
      (LIFECYCLE - %w[intake] + %w[remediate]).each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_any!(dir, "phases complete")
      sealed_rounds!(dir, record, 2)
      record.update_metadata { |m| m.delete("rules") }
      reopen_out = begin
        reopen(dir, record, "remediate")
        "reopen PERMITTED"
      rescue SoftFoundry::TargetError
        "reopen refused"
      end
      %w[remediate review judge].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_any!(dir, "round three worked")
      sealed_rounds!(dir, record, 1)
      caps = %w[review judge].map { |id| "#{id} cap=#{check(gate(dir, record, id), 'remediation within cap').outcome}" }
      kept = check(gate(dir, record, "intake"), "rules kept")
      observe("ATTACK-008a", "intake seal=#{intake_seal.outcome}; after dropping rules: #{reopen_out}; three rounds sealed; #{caps.join(', ')}; intake gate rules kept=#{kept.outcome}")
      assert_equal "reopen refused", reopen_out, "dropping rules: after intake must not disarm the reopen refusal"
    end
  end

  # ATTACK-008b: drop the rules version before the intake seal.
  def test_attack_008b_rules_dropped_before_intake_seal
    with_lifecycle_record(complete: [], current_phase: "intake") do |dir, record|
      new_rules!(record)
      commit_any!(dir, "change new wrote rules")
      record.update_metadata { |m| m.delete("rules") }
      complete_phase!(record, "intake", sha: head(dir))
      result = seal(dir, record, "intake")
      kept = check(gate(dir, record, "intake"), "rules kept")
      observe("ATTACK-008b", "intake seal=#{result.outcome}; lines=#{result.lines.join(' | ')[0, 300]}; rules kept=#{kept.outcome} (#{kept.detail})")
      assert_includes result.lines.join, "rules", "the seal must at least name the dropped rules key"
    end
  end

  # ATTACK-009 / THREAT-008: README plus one lib/ file must size large;
  # the record path of another change is not documentation.
  def test_attack_009_mixed_diff_sizes_large
    with_lifecycle_record(complete: LIFECYCLE - %w[verify evaluate attack review judge]) do |dir, record|
      new_rules!(record)
      commit_any!(dir, "base")
      base = head(dir)
      File.write(File.join(dir, "README.md"), "# readme\n")
      FileUtils.mkdir_p(File.join(dir, "changes", "c1-evil"))
      File.write(File.join(dir, "changes", "c1-evil", "x.rb"), "puts 9\n")
      commit_all(dir, "docs plus another record")
      sizing = SoftFoundry::Sizing.new(record, git: git(dir))
      r = sizing.compute("attack", since: base)
      observe("ATTACK-009", "size=#{r.size} reasons=#{r.reasons.inspect}")
      assert_equal sizing.sizes("attack").last, r.size
    end
  end

  # ATTACK-010: a malformed cap decision is refused, and the failure names the field.
  def test_attack_010_malformed_cap_decision
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 3)
      decide!(record, { "boundary" => "remediation cap", "rounds" => "2", "decision" => "Accept_Residual", "decided_by" => "maintainer", "decided_at" => "2026-11-14" })
      c = check(gate(dir, record, "review"), "remediation within cap")
      observe("ATTACK-010", "cap=#{c.outcome}; detail=#{c.detail}")
      assert_equal :fail, c.outcome
      assert(c.detail.include?("rounds") && c.detail.include?("decision"), "the failure should name the malformed fields")
    end
  end

  # ATTACK-011: terminal escape in a follow_up is neutralised in advisories.
  def test_attack_011_escape_in_follow_up
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record)
      esc = "\u001b[2J\u001b]0;pwned\u0007"
      record.update_handoff(record.control_plane.phase("attack")) do |h|
        h["findings"] = [{ "id" => "ATK-X", "summary" => "s#{esc}", "outside_change" => true, "follow_up" => "f#{esc}", "paths" => ["lib/other.rb"] }]
      end
      notices = SoftFoundry::Advisory.new(record, git: git(dir)).notices.select { |n| n.area == "follow-up" }
      text = notices.map(&:message).join
      observe("ATTACK-011", "follow-up notices=#{notices.size}; raw ESC present=#{text.include?("\u001b")}; BEL present=#{text.include?("\u0007")}")
      refute_empty notices
      refute text.include?("\u001b")
      refute text.include?("\u0007")
    end
  end

  # ATTACK-002c: with git.branch left redirected, rerun the stale review at
  # a new commit: can the review gate then pass with three rounds and no decision?
  def test_attack_002c_review_rerun_under_redirect
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 3)
      text = File.read(File.join(record.dir, "metadata.yml"))
      File.write(File.join(record.dir, "metadata.yml"), text.sub(/^  branch: .*$/, "  branch: main"))
      commit_any!(dir, "redirect")
      complete_phase!(record, "review", sha: head(dir))
      commit_any!(dir, "Record c1 review")
      r = gate(dir, record, "review")
      failing = r.checks.reject { |c| %i[pass skip warn].include?(c.outcome) }.map { |c| "#{c.name}=#{c.outcome}: #{c.detail.to_s[0, 160]}" }
      observe("ATTACK-002c", "cap=#{check(r, 'remediation within cap').outcome}; non-passing=#{failing.inspect}")
      refute_empty failing, "the review gate must not pass with three unanswered rounds"
    end
  end

  # ATTACK-005f: the realistic way out of a documentation-only refusal: the
  # remediation handoff is complete (the session finished it), the seal is
  # refused, the person runs `phase reopen remediate` as advised.
  def test_attack_005f_docs_only_escape_when_handoff_complete
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      docs_only_setup(dir, record)
      File.write(File.join(dir, "lib", "app.rb"), "puts 'real fix'\n")
      commit_all(dir, "code fix")
      complete_phase!(record, "remediate", sha: head(dir))
      refused = seal(dir, record, "remediate")
      r = reopen(dir, record, "remediate")
      rounds = SoftFoundry::ProcessRules.new(record, git: git(dir)).remediation_rounds
      complete_phase!(record, "remediate", sha: head(dir))
      after = seal(dir, record, "remediate")
      observe("ATTACK-005f", "first seal=#{refused.outcome}; reopen remediate reset=#{r.reset.map(&:id).inspect}; rounds counted before second seal=#{rounds}; seal after=#{after.outcome}: #{after.lines.join(' ')[0, 220]}")
      refute_equal :refused, after.outcome
    end
  end

  # ATTACK-002d: end to end. Redirect git.branch only for the reopen, restore
  # it, do the third round, and seal it; then try sealing review while the
  # branch is still redirected.
  def test_attack_002d_redirect_end_to_end
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      meta = File.join(record.dir, "metadata.yml")
      original = File.read(meta)
      File.write(meta, original.sub(/^  branch: .*$/, "  branch: main"))
      r = reopen(dir, record, "remediate")
      File.write(meta, File.read(meta).sub(/^  branch: .*$/, "  branch: change/c1"))
      status_after_reopen = record.metadata["status"]
      commit_any!(dir, "reopened")
      complete_phase!(record, "remediate", sha: head(dir))
      rem = seal(dir, record, "remediate")
      File.write(meta, File.read(meta).sub(/^  branch: .*$/, "  branch: main").sub(/^status: .*$/, "status: in_progress"))
      complete_phase!(record, "remediate", sha: head(dir))
      rem2 = seal(dir, record, "remediate")
      observe("ATTACK-002d", "reopen under redirect reset=#{r.reset.map(&:id).inspect}, status=#{status_after_reopen}; seal remediate after restoring branch=#{rem.outcome} (#{rem.lines.join(' ')[0, 110]}); seal remediate under redirect=#{rem2.outcome} (#{rem2.lines.join(' ')[0, 140]})")
      assert_equal :refused, rem.outcome
      assert_equal :refused, rem2.outcome
    end
  end
  # ATTACK-012 / THREAT-002 (first vector): delete the remediate entries from
  # phase_reopenings after two sealed rounds, then reopen remediation.
  def test_attack_012_delete_reopen_entries
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 2)
      record.update_metadata { |m| m["phase_reopenings"] = [] }
      commit_any!(dir, "drop reopen history")
      rounds = SoftFoundry::ProcessRules.new(record, git: git(dir)).remediation_rounds
      out = begin
        reopen(dir, record, "remediate")
        "reopen PERMITTED"
      rescue SoftFoundry::TargetError => e
        "reopen refused; status=#{record.metadata['status']}"
      end
      observe("ATTACK-012", "phase_reopenings emptied and committed; rounds counted=#{rounds}; #{out}")
      assert_equal 2, rounds
      assert_includes out, "refused"
    end
  end

  # ATTACK-013 / THREAT-001: the fabricated approval of ATTACK-001, but
  # committed by hand before the seal, so metadata.yml is clean at seal time.
  def test_attack_013_committed_fabricated_approval_escapes_seal_note
    with_lifecycle_record(complete: %w[intake discover], current_phase: "specify") do |dir, record|
      new_rules!(record, risk: "high")
      commit_any!(dir, "rules")
      # The fixture's complete_phase! fills specify with its own approval
      # entry; replace it with the forged one and commit everything by hand,
      # so metadata.yml is clean against HEAD when the seal runs.
      complete_phase!(record, "specify", sha: head(dir))
      criteria!(record, [["AC-001", "must"], ["AC-002", "should"]])
      record.update_metadata { |m| m["human_decisions"] = [{ "boundary" => "must criteria approval", "criteria" => ["AC-001"], "decided_by" => "maintainer", "decided_at" => "2026-11-14", "decision" => "approved" }] }
      commit_any!(dir, "wording")
      dirty = sh(dir, "git", "status", "--short", "changes/c1/metadata.yml").strip
      result = seal(dir, record, "specify")
      g = gate(dir, record, "specify")
      approved = check(g, "must criteria approved")
      failing = g.checks.reject { |c| %i[pass skip warn].include?(c.outcome) }.map { |c| "#{c.name}: #{c.detail.to_s[0, 140]}" }
      observe("ATTACK-013", "gate failing=#{failing.inspect}; metadata.yml dirty before seal=#{dirty.empty? ? 'no' : dirty}; seal outcome=#{result.outcome}; must criteria approved=#{approved.outcome}; lines=#{result.lines.inspect}")
      assert_includes result.lines.join("\n"), "human_decisions", "a decision that first appears in a hand commit should still be named at the seal"
    end
  end

  # ATTACK-014 / THREAT-008 (risk word): lower risk from high to low in a
  # hand commit after the intake seal. Default waivers then step over attack.
  def test_attack_014_risk_lowered_by_hand_commit
    with_lifecycle_record(complete: [], current_phase: "intake") do |dir, record|
      new_rules!(record, risk: "high")
      commit_any!(dir, "rules")
      complete_phase!(record, "intake", sha: head(dir))
      intake = seal(dir, record, "intake")
      before = SoftFoundry::ProcessRules.new(record, git: git(dir)).default_waivers
      record.update_metadata { |m| m["risk"] = "low" }
      commit_any!(dir, "tidy")
      after = SoftFoundry::ProcessRules.new(record, git: git(dir)).default_waivers
      complete_phase!(record, "discover", sha: head(dir))
      sealed = seal(dir, record, "discover")
      w = check(gate(dir, record, "intake"), "waivers permitted")
      observe("ATTACK-014", "intake seal=#{intake.outcome}; default waivers before=#{before.inspect} after=#{after.inspect}; discover seal=#{sealed.outcome} lines=#{sealed.lines.inspect}; intake gate waivers permitted=#{w.outcome} (#{w.detail})")
      assert_includes sealed.lines.join, "risk", "a risk lowered after intake should be named somewhere a person sees it (MIT-008)"
    end
  end

  # ATTACK-015 / THREAT-003: reuse one cap decision for a further round.
  # The decision at rounds: 2 lets round three through; four sealed rounds
  # need a second decision (rounds: 3). Only the first is recorded.
  def test_attack_015_stale_cap_decision
    with_lifecycle_record(complete: LIFECYCLE + %w[remediate]) do |dir, record|
      new_rules!(record)
      sealed_rounds!(dir, record, 4)
      decide!(record, { "boundary" => "remediation cap", "rounds" => 2, "decision" => "accept_residual", "decided_by" => "maintainer", "decided_at" => "2026-11-14" })
      outs = %w[review judge].map { |id| "#{id}=#{check(gate(dir, record, id), 'remediation within cap').outcome}" }
      observe("ATTACK-015", outs.join(", "))
      assert_equal %w[review=fail judge=fail], outs
    end
  end

  # ATTACK-016 / THREAT-006: the modified path given as an absolute path.
  def test_attack_016_outside_change_absolute_path
    with_lifecycle_record(complete: LIFECYCLE) do |dir, record|
      new_rules!(record)
      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "change app")
      spelling = File.join(dir, "lib", "app.rb")
      record.update_handoff(record.control_plane.phase("review")) do |h|
        h["findings"] = [{ "id" => "REV-001", "severity" => "major", "summary" => "s", "failure" => "f", "outside_change" => true, "follow_up" => "x", "paths" => [spelling] }]
      end
      o = check(gate(dir, record, "review"), "outside-change findings").outcome
      observe("ATTACK-016", "absolute path of the modified file => #{o}")
      refute_equal :pass, o
    end
  end
end
