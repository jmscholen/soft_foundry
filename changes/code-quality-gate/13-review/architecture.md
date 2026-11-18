# Architecture Review

## Scope reviewed
How applicability is modelled: `enabled_by` and `since_rules` on the lifecycle entry (`.ai/workflow.yml`, `ControlPlane::Phase`), read by `ChangeRecord#asked_for?`. Also the reuse of `waivable_by_risk.low` and the light track's `optional` list for the risk and track table; `ProcessRules::CURRENT` against `VERSION`; the gate's per-phase check lists; and the UI snapshot's own `skip_reason`. Implementation decisions (`05-implementation/decisions.md`) were read against the code.

The code-quality phase did not run for this change. The record is `rules: 2` on the light track, and this repository's profile sets `quality_gate.enabled: false` (maintainer). This section and `functional.md` therefore cover design, duplication and clarity as this review saw them.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-004 | minor | `lib/soft_foundry/snapshot.rb:257-262` | The UI snapshot has its own `skip_reason`, separate from `ChangeRecord#skip_reason`, and it was not taught about conditional phases. In `soft-foundry ui`, a record that is not asked for the quality phase shows `06a-code-quality` pending with no reason, while `change status` gives one. Two copies of the "why pending" rule have already drifted once here. | In `soft-foundry ui`, the cell for a record made before this change, or in a repository with the gate off, reads as open work with no skip reason. REQ-010 names `change status` only, so this does not miss the specification. | REQ-010 (beyond its wording) |
| REV-005 | minor | `lib/soft_foundry/gate.rb:122-131,187-215` | The check lists repeat `%w[review judge].include?(phase.id) \|\| phase.id == QUALITY` in six places, in two parallel methods (`checks_for` and `evaluate`). Adding the phase meant editing both in step. A table of check names per phase would keep them together. | A future check added to one list and not the other makes `gate --explain` and the actual gate disagree. That is a maintenance cost and no fault today. | Clarity |

## Conformance
Conforms with minor findings. The data-driven applicability (`enabled_by`, `since_rules`) is the right altitude: the rule sits in `workflow.yml` beside the other applicability rules, and a future conditional phase needs no code. Keeping `ProcessRules::VERSION` at 2 and adding `CURRENT = 3` correctly avoids turning every `rules: 2` record into a legacy record. `convergence?` already reads `>= VERSION`. Reusing `waivable_by_risk` and the track's `optional` list adds no new mechanism. The `06a-` directory name keeps existing records' directory names stable.
