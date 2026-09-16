# Architecture Review

## Scope reviewed
Where tracks live (`ControlPlane`), where the stage's state lives (`ChangeRecord`), which checks moved into `Gate`, what the CLI owns versus the record, and the `Check` refactor onto `check_skill_contract`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-007 | info | `lib/soft_foundry/control_plane.rb` `Track`, `tracks` | Tracks are policy read from `workflow.yml` like phases and transitions, with an implicit `gated` when absent, so older installed planes need no migration. `hardening_phase?` is the single definition of "from implement onward" used by the gate and by `reopen!`. | `.ai/rules/architecture.md` |
| REV-008 | info | `lib/soft_foundry/change_record.rb` `skippable?` | One predicate now answers "may this phase stay pending" for the gate's predecessor check and for `reached_lifecycle_end?`, replacing two copies of the skipped-with-rationale logic. Track-optional phases join the same rule rather than adding a third. | `.ai/rules/architecture.md` |
| REV-009 | info | `lib/soft_foundry/cli.rb` `change_vet` vs `ChangeRecord#vet!` | Preconditions live in the CLI (they are messages to a person); the record only knows how to write the transition. Same split as `change close` / `close!`. `vet` re-derives the risk-forces-track fact the gate also reports, in words a person can act on. | `.ai/rules/architecture.md` |
| REV-010 | info | `lib/soft_foundry/check.rb` | `check_phase` and the new stage-skill lint share `check_skill_contract(name, owner, phase:)`; the only difference is whether `handoff.yml` must be required. `check_exploring_writes` reuses `overlap?`. | `.ai/rules/architecture.md` |
| REV-011 | minor | `.ai/skills/exploration/permissions.yml` | The stage skill writes `05-implementation/**` and `02-specification/**` as well as `exploration/**`. Neither is commit-bound evidence, so the lint accepts it, but the specification is the thing a later vet locks; a stage skill that could not write it would need the specification skill loaded alongside, which the AGENTS contract (one skill at a time) does not allow. Accepted with the reasoning in `decisions.md`. | `.ai/policies/skill-permissions.yml` |

## Conformance
Conforms.
