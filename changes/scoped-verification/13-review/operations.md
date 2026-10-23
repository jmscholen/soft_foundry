# Operations Review

## Scope reviewed

REQ-018, REQ-019, and REQ-020; `.ai/rules/observability.md` (no new service, so the dashboard baseline does not apply); `04-plan/rollback.md`; the advisory text in `advisory.rb`; status and the browser note in `app.js`. `surfaces.observability` is false. Phase 12-observability is still pending. This phase did not rerun the suite.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `Gate#staleness_check` via `Scope.tip_for`; status, phase-run refusal, and the browser all read that result (REQ-019) | When the measure is the laundered branch, status, `ci`, and the scope advisory describe that branch as current. The operator is not told that code landed on the checked-out branch. Rollback step 4 treats a blocking review finding as a return to verify; that is the right recovery once this is repaired. | The ATTACK-019 input. `gate verify` exits 0 with `evidence current` "no code changes since … on branch frozen". A person reading status or the browser sees a current record. | REQ-019. REQ-020. `.ai/rules/observability.md` (a material failure mode needs a detection path). |
| REV-004 | minor | `gate verify` on scalar `git` | The failure is an unhandled `TypeError` and names no field and no next step, so an operator cannot tell a malformed record from a crash. | `git:` set to a string. Exit 1, message `String does not have #dig method` (`transcript3.txt`, ATTACK-018). | REQ-016. `.ai/rules/errors.md`. |

The three REQ-018 advisories (paths outside the scope, shared core without a recorded full run, scope matching no changed file) print and do not block the gate. ATTACK-015 shows the overlap advisory and the outside-scope advisory while the gate still exits 0, which is the specified advisory behavior, not a separate defect. See REV-003 in the security review for the claim rule underneath that pass.

## Conformance

Does not conform. REV-001 makes the operational surfaces report the frozen branch as current. The detection path for that failure mode is the attack transcript, not status or the gate.
