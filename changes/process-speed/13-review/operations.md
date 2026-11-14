# Operations Review

## Scope reviewed

The operational surface the specification names: the reopen refusal, parked `status`, `change status` advisories, `change summary`, default waivers on `waivers permitted`, the docs-only flag, and the `ui` snapshot's existing status field. `surfaces.observability` is false. There is no runtime metric, alarm, or dashboard, and `.ai/rules/observability.md` does not add one for a library with no service. The observability phase record is still the unused template; this review did not need it, because the specification says the record is the surface.

Also read: `PhaseRunner` refusing to start a session while status is `awaiting_human`, `Release` copying `person_checks` into release items, and the committed operator text in `README.md` and `docs/user/converging-changes.md`. The product-documentation and FAQ phase directories are still unused templates. The user-facing text that exists is the committed README and `docs/user/converging-changes.md`.

Verification recorded the full suite and `soft-foundry ci` passing with provider keys and `SOFT_FOUNDRY_PHASE` unset (AC-018). This review did not re-run that suite.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-005 | major | `ProcessRules#cap_refusal` | The parked-status message is the operator's instruction, and it states a false seal count when the count includes a remediation that was refused and never sealed. The change does park, which is the safe direction, and the words the person must act on are wrong. | See REV-005 in `functional.md`. The operator is told two rounds were sealed and must record a decision before a second seal the specification still allows. | REQ-002; specification, Observability expectations |
| REV-007 | minor | `Gate#cap_check` | The gate line an operator reads when a decision is malformed does not name the field, and the round number in the sentence is not the `rounds` value it tells them to write. | See REV-007 in `functional.md`. An operator who follows "round 3" writes `rounds: 3` and the check still fails, because it required `rounds: 2`. | Specification, Failure behavior |
| REV-010 | minor | `docs/user/converging-changes.md`, `README.md` | Operators are not told that `rules kept` exists or what it refuses. The cap, tiers, approval, blocked basis, and outside-change checks are named. | See REV-010 in `functional.md`. | REQ-014 |
| REV-012 | minor | `cap_refusal` | One 506-character line is the whole operational instruction at the cap. | See REV-012 in `accessibility.md`. | `.ai/rules/accessibility.md` command-line rules |
| REV-014 | minor | `PhaseReopen#refuse_status!` | The second refusal, after the change is already parked, drops the decision words the operator needs. | See REV-014 in `accessibility.md`. | REQ-016 |

## Conformance

Does not conform, because of REV-005: the status the operator is told to act on reports a seal count that did not happen. The rest of the surface works as specified on the cases evaluation drove: a refused reopen writes only `status: awaiting_human`, `phase run` starts no session while parked, person checks become release items, and default waivers are listed by `waivers permitted`. REV-007, REV-010, REV-012, and REV-014 are gaps in what that surface says.
