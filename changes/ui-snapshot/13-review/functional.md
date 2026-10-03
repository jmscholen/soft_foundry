# Functional Review

## Scope reviewed
`lib/soft_foundry/change_index.rb`, `lib/soft_foundry/snapshot.rb`, the additions to `gate.rb`, the `cli.rb` changes, the three new test files, and the evaluation transcript, against REQ-SNAP-001..007.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | All seven requirements are implemented and each is exercised by a test and a journey. | REQ-SNAP-001..007 |
| REV-002 | minor | `Snapshot#timeline` | An event whose recorded time is a placeholder or free text (a `decided_at` of "soon") is kept and sorted last rather than dropped. It should be left out or marked as having no usable time. Fix in `ui-explainer-timeline`, where the view is built, with a test. | REQ-SNAP-005 |
| REV-003 | minor | `Snapshot#change` | A ledger whose `entries` holds a non-mapping raises from `Budget#entries`, so that one change's detail fails where the board does not. The server in the next change must turn that into an error response; the snapshot could also report spend as unreadable. | REQ-SNAP-003 in spirit |
| REV-004 | minor | `Gate.checks_for` | The test compares the listed checks with what the gate ran for intake only. Verify, specify, and learn have phase-specific checks that are listed correctly today but not compared. | REQ-SNAP-002 |

## Conformance
Conforms, with three minor findings carried to the next changes.
