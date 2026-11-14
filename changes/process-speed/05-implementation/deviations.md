# Deviations From Plan

## DEV-001: AC-003's automatic reopen is reached through verify, not remediate
- **What changed.** AC-003 says `phase run remediate` would reopen a stale remediation automatically. Remediation's skill is not commit-bound (`.ai/skills/remediation/skill.yml` declares no `evidence: commit_bound`), so the gate never reports it stale and the runner never reopens it. The automatic reopen that can start another round is a stale verify, whose reset includes a complete remediation. `test/cli_process_speed_test.rb` tests that path: `phase run verify` at the cap starts no session, prints the cap refusal and parks the change.
- **Why.** The criterion's scenario cannot occur; the behaviour REQ-002 asks for ("any reopen whose reset would include remediation, manual or automatic") is what is tested.
- **Requirements affected.** REQ-002 unchanged; AC-003 (should) is met by the reachable path.
- **Approval.** None needed for a should criterion's wording; review and judgment read this entry.

## DEV-002: an unclassified risk warns instead of failing the must cap
- **What changed.** The plan's `criteria tiered` check had no rule for a risk that is unset or a placeholder. The check warns and applies no cap, so every must criterion stays binding.
- **Why.** Failing would refuse every specification written before intake classified the risk, including the existing test fixtures; applying the smallest cap would loosen what binds. No cap is the strict side, matching how an unclassified risk may waive nothing.
- **Requirements affected.** REQ-004 (the cap applies "for the change's declared risk"; an undeclared risk has none).
- **Approval.** Review and judgment read this entry.

## DEV-003: planted specifications carry tiers and an approval
- **What changed.** `HarnessEval.complete_phase!` (shared by the suite and the harness evals) now gives a planted specification on a `rules: 2` record a tier on each untiered criterion (must) and a planted approval naming exactly the must criteria, `decided_by: harness`.
- **Why.** `change new` now writes `rules: 2`, so every fixture is a new-rules record; without this every planted specification failed the two new specify checks. A plant already fills evidence the gate accepts; this fills the two new facts the same way.
- **Requirements affected.** None; fixtures only. It does mean the suite's fixtures exercise the new rules by default.
- **Approval.** Review reads this entry.

## DEV-004: specify is never a default waiver (maintainer decision, 2026-11-13)
- **What changed.** `ProcessRules::NEVER_DEFAULT_WAIVED = [specify]`: at a risk listed in `default_waivers`, every phase `waivable_by_risk` lists is stepped over by default except the specification. An explicit `skipped_phases` entry with a rationale still waives it. AC-012 (should) names specify among the reported default waivers; it is no longer one.
- **Why.** The specification is where a person approves the must list (REQ-005). Skipping it by default at low risk would remove the human checkpoint this change exists to add. The maintainer, asked in the implementing session before implementation was sealed, chose to keep it.
- **Requirements affected.** REQ-010 narrowed by one phase; AC-012's listed phases become discover, threat_model, plan and learn (attack stays required in its fixture through run_phases). REQ-005 is preserved at low risk.
- **Approval.** The maintainer, in session ("go ahead", 2026-11-13). Tested by `test_specify_is_never_a_default_waiver` (RED 62cf9a1).
