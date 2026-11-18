# Architecture Review

## Scope reviewed
How applicability is modelled: `enabled_by` and `since_rules` on the lifecycle entry (`.ai/workflow.yml`, `ControlPlane::Phase`), read by `ChangeRecord#asked_for?`. Also covered:
- the reuse of `waivable_by_risk.low` and the light track's `optional` list;
- `ProcessRules::CURRENT` against `VERSION`;
- the gate's per-phase check lists;
- the UI snapshot's own `skip_reason`;
- the remediation's new `MaturityScan#set_by_a_person?`.

HEAD is `1650d93`. Code outside `maturity_scan.rb` is unchanged since the first review.

The code-quality phase did not run for this change. The record is `rules: 2` on the light track, and this repository's profile sets `quality_gate.enabled: false` (`set_by: maintainer`). This section and `functional.md` therefore cover design, duplication and clarity.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-004 | minor | `lib/soft_foundry/snapshot.rb:257-262` | Still open. The UI snapshot has its own `skip_reason`, which knows nothing of conditional phases. `soft-foundry ui` shows `06a-code-quality` pending with no reason, while `change status` gives one. | In the UI, a phase that was not asked for reads as open work. REQ-010 names `change status` only. | REQ-010 (beyond its wording) |
| REV-005 | minor | `lib/soft_foundry/gate.rb:122-131,187-215` | Still open. The per-phase check lists are repeated in `checks_for` and `evaluate`. | A check added to one list but not the other would make `gate --explain` disagree with the gate. | Clarity |

## Conformance
Conforms with minor findings. The remediation is small and well placed. A named predicate (`set_by_a_person?`) replaces an inline condition, and its comment states both cases it excludes: blank, and written by the scan. It adds no new mechanism.
