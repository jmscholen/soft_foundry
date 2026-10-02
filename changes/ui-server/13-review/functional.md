# Functional Review

## Scope reviewed
`lib/soft_foundry/ui/server.rb`, the three page files, the `ui` command in `cli.rb`, the remediation in `snapshot.rb`, three new test files, and the evaluation and attack evidence, against REQ-UI-001..009.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Each requirement is implemented and has a test or a recorded observation. | REQ-UI-001..009 |
| REV-002 | minor | `UI::Server#cached`, the board | The board gates every open record on each uncached poll, about 0.4 s each. Three open records cost 0.67 s every 5 s while a tab is visible. Past roughly ten open records a poll would take as long as the interval. A gate result keyed on HEAD and the record's modification times would fix it. | REQ-UI-004 |
| REV-003 | minor | `UI::Server#change` | A change request builds the index twice (once to validate the slug, once in the snapshot). | Simplicity |
| REV-004 | minor | `UI::Server#respond` | HEAD on a data route computes the full answer to report its length. | REQ-UI-004 |
| REV-005 | info | `app.js` `navigate` | Selecting a gate redraws from the data already on screen, so it is instant and makes no request. | REQ-UI-006 |
| REV-006 | minor | `app.js` | The page has no test that runs it. Its safety floor is asserted on the source text, and its behaviour was observed in one browser by hand. | `.ai/rules/testing.md` |

## Conformance
Conforms, with minor findings. REV-006 is the largest gap: the script's behaviour rests on a recorded manual pass.
