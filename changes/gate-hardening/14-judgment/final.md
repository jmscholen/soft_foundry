# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
5c87870433214069d91efd14fc43d36a73933f97 (`Record gate-hardening review`). Code under `lib/`, `test/` and `.ai/` last changed at GREEN `c664d12` (the third remediation); nothing under those paths differs between `dccdd8c` and HEAD (`git diff --stat dccdd8c HEAD -- lib test .ai exe docs` is empty). The four evidence phases were each sealed at a commit after `c664d12` and describe that same code.

## Requirements status
REQ-001 to REQ-036 are met as far as the evidence reaches. Verification passed the full suite (902 runs, 0 failures, with and without a phase session's environment), `check`, `eval` (28 gate cases), `ci` and the RED/GREEN shape of every remediation file. Evaluation passed all 19 journeys, which cover AC-001 to AC-047, AC-049, AC-052 and AC-055. AC-053 was answered by attack; AC-054 by this judgment. AC-051's `docs/user/` clause is owed by the documentation phases, which did not run (see Documentation). AC-019 has no planned unit test; it rests on `check`, `eval` and the checks listing (VER-002, REV-003).

## Verification
`06-verification` is complete at `dccdd8c`, the record commit for the third remediation, with the code at `c664d12`. One check fails, CHECK-011: the planned test `test_lint_accepts_new_check_names` was never written. It is a coverage gap and does not touch behaviour. VER-003 (a test-isolation defect in `harness_eval_test.rb:198` when other processes run harness evals) is a test fragility and does not affect the product. Current.

## Evaluation
`07-evaluation` is complete at `b871187`. All 19 journeys pass. The two earlier failures are cleared: EVAL-017/019 (`gate all` 1.42 s against 1.18 s for the pre-change gem, ratio 1.20 against a bound of under 2; 71 git calls against 64) and EVAL-018 (every lineage refusal names a next action). Current.

## Attack
`08-attack` is complete at `47583ef`. ATTACK-001 to ATTACK-029 ran against scratch repositories. ATK-001 to ATK-008, ATK-010 (for the routes ATTACK-023 and ATTACK-024 attack), ATK-011, ATK-012 and ATK-013 are confirmed closed. One major finding remains: ATK-014. The ATK-010 fix identifies the seal commit by its subject `Record <slug> <phase>`, so a committer who rewrites a sealed phase's `commit_sha` to HEAD and hand-commits the handoff under that subject makes stale evidence read current. Minor residue: ATK-015 (a rerun is any changed byte), ATK-016 (`enforcement.yml` shape), ATK-017 (`already sealed` for a hand-committed phase), ATK-018, and the carried ATK-003 and ATK-009. The attack phase proposed `next: remediate` for ATK-014.

## Documentation
Phases 10 (user documentation), 11 (FAQ index) and 12 (observability) are optional, still pending, and absent from `skipped_phases` in `metadata.yml`. The change adds CLI behaviour and a tool-internal gate, `surfaces.application` and `surfaces.infrastructure` are false, and the review (operations) found no new failure mode needing a runbook, so I accept their absence. The AC-051 `docs/user/` clause was not evidenced by any phase read here; a person should confirm the user docs mention `phase seal` and the lineage refusals before release. This is carried as a residual item, not a blocker.

## Observability
`surfaces.observability` is false; the change is a local CLI tool with no deployed service, and the `12-observability` templates are untouched. Gate and seal output are the operator surface, and the review rated them conforming with accessibility advisories (REV-008, REV-009).

## Review findings
`13-review` is complete at `5eb5b1a` with no blocking findings. REV-001 (major) restates ATK-014 and leaves the choice, including BLOCKED, to this judgment. REV-002 to REV-011 are minor and carried.

## Decision and reasoning
ATK-014 is real but I judge it acceptable for release as a named open item rather than a reason to return to verify:
- It is not a regression. The pre-change gate accepted the same hand commit, and the locked specification states a committer can still edit any file and that the gate makes a fake detectable, not impossible. Every route the attack phase tried that a non-deliberate or tool-assisted path could reach is now closed.
- The route needs a deliberate committer who forges both a handoff and a commit subject. It does not corrupt a record by accident, and the forged commit stays visible in history.
- Reopening would send the change through verify, evaluate, attack and review a fifth time (about 16 minutes per suite run alone) for a hardening step the specification does not require.
- The fix is clear (a commit trailer or a required `phase_reopenings` entry with changed evidence) and fits a follow-up change.

I did not choose APPROVED: a major finding that weakens the integrity claim of THREAT-001 for a deliberate committer remains, and it must stay in the record. I did not choose BLOCKED or REJECTED: no requirement is unmet and no evidence is stale.

## Residual risk
See `residual-risk.md`. Release should go through `soft-foundry change release` with ATK-014 named as an open item.
