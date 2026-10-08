# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and the operational consequences of the panel runner. `surfaces.observability` is false. The repository profile marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE: there is no production service; the CLI exits non-zero. `12-observability/` is still the pending template. This change does not add a service, a dashboard, or an alarm, and none is owed for a library gem.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-001 | major | see `functional.md` | Recorded here so operations does not drop it. The panel's new failure mode (a member process exits non-zero, or a later executable is missing) is not detected as a failure. It is either a command that exits 0 with the phase still pending, a change parked as a panel split, or an orphaned member process. `soft-foundry ps` will not list a killed panel as an unfinished run, because `executed_by` is written only at the end and then with `exit_status` 0. | Same input as in `functional.md`: consensus exits non-zero after agreement, or every member exits non-zero without writing, or the second shell is not on PATH. | `.ai/rules/observability.md` (a new material failure mode needs a detection path); `.ai/rules/general.md` |

No second finding. Production dashboard and alarm rules do not apply.

## What holds

A genuine disagreement still exits non-zero, prints `! warn panel: split`, and parks the change. That path is observable. The single-provider case prints `! warn panel:`. Refusals exit non-zero (see REV-A11Y-001 for the missing status word). Billing notices still print per shell before the panel starts.

## Conformance

The production observability standard is not applicable. The CLI failure mode in REV-FUN-001 does not conform to the detection rule.
