# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
`79ab0c2` (HEAD, `Record code-quality-gate review`). The code it holds is the remediation's GREEN commit `b118833`. Every commit after `b118833` touches only `changes/code-quality-gate/`. `git diff --stat b118833 HEAD -- . ':!changes'` is empty.

## Requirements status
The record is under the convergence rules (`rules: 2`). It is held to its must criteria, AC-001 to AC-004, which the maintainer approved on 2026-11-16.

| Criterion | Tier | Status | Evidence |
| --- | --- | --- | --- |
| AC-001 | must | met | CHECK-001 (`test_evaluation_waits_for_quality_where_the_gate_is_on`, `test_sealing_verify_makes_quality_the_current_phase`), CHECK-004 |
| AC-002 | must | met | CHECK-001 (low risk, light track, earlier rules number, no rules number, gate off or unnamed, `change status` reasons), CHECK-005 |
| AC-003 | must | met | CHECK-001 (classed blocking finding blocks and points to remediation; no class, bad class or no failure fails the gate; major or lower can complete) |
| AC-004 | must | met | CHECK-001 (`test_the_quality_phase_writes_only_its_own_directory`), security review |
| AC-005 | should | met | CHECK-001 (text checks of the skill and templates) |
| AC-006 | should | met | CHECK-001 (staleness, reopen resets quality) |
| AC-007 | should | met | CHECK-001 (fresh-session check in block mode) |
| AC-008 | should | partly met | Covered by structure only: the quality gate carries the shared remediation-cap check. No test drives a third round (VER-001, REV-002). |
| AC-009 | should | met | CHECK-001 (help and documentation) |
| AC-010 | should | met | CHECK-002 full suite 980 runs, 0 failures; CHECK-005 `ci`; CHECK-006 existing-test edits match DEV-004. One edit is the rules number, not a phase count (REV-003); REQ-004 requires it. |
| AC-011 | should | met | CHECK-001 (Rails rules and remediation steps) |
| AC-012 | should | met | CHECK-001, CHECK-003, CHECK-007 (Ruby gets the gate on, Go-only gets it off, a person's false is kept) |

No must criterion is unmet. PC-001 is a person check after merge and is carried by `change release`.

This session reran `test/code_quality_gate_test.rb` with provider keys and `SOFT_FOUNDRY_PHASE` unset: 29 runs, 223 assertions, 0 failures. It also read `MaturityScan#quality_gate` and `#set_by_a_person?` at HEAD. They match what remediation, verification and review describe.

## Verification
Complete at `459fa86`, describing code `b118833`, and still current. The full suite (980 runs, 0 failures, 0 errors, 0 skips), targeted tests, `check`, `ci`, and the scratch onboarding checks all pass. RED evidence for the remediation is at `55448aa`. The run was a fresh session (`executed_by` stamped).

## Code quality
Not run (`06a-code-quality`). The record predates the phase (`rules: 2`), the light track makes it optional, and this repository's profile sets `quality_gate.enabled: false`. It is recorded as `not_run`, not as a pass. Design, duplication and clarity were covered by review (`architecture.md`, `functional.md`).

## Evaluation
Not run. Optional on the light track.

## Attack
Not run. Optional on the light track. The security review found nothing an outside party can reach.

## Documentation
The user documentation phase is optional and was not run. The change ships `docs/user/code-quality-review.md`, README and help text. Review checked these and AC-009 passes.

## Observability
The observability phase is optional and was not run. `change status` names the phase and why it may stay pending (REQ-010). The UI snapshot does not (REV-004, minor).

## Review findings
Second review at `1650d93`, fresh session, no blocking findings. REV-001 (blocking in the first review) is resolved at `b118833`. REV-002 to REV-005 and REV-007 to REV-009 are minor and open. REV-006 is minor and outside this change. Remediation used round 1 of 2, so the cap was not reached.

## Residual risk
See `residual-risk.md`. In short:
- AC-008 is tested only by structure.
- The gate's check lists are duplicated, and the UI shows no skip reason.
- There is no harness eval case for the new check.
- Remediation made a disclosed comment-only control-plane edit under the maintainer's override.
- Every evidence phase ran on the same provider as implementation.
- A stray guard file is untracked in the record.
