# Functional Review

## Scope reviewed
`lib/soft_foundry/processes.rb`, the `ps` command, the `/api/processes` route, the page additions, the tests, and the evaluation and attack evidence, against REQ-PS-001..008.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Each requirement is implemented, with tests for the data and command and recorded observations for the page. | REQ-PS-001..008 |
| REV-026 | major (process) | first delivery | The change shipped listing none of the five sessions the maintainer had open, with tests, evaluation, and review all passing, because each was written against the implementer's reading of the request. The limit was even written down as a non-goal. Fixed in remediation; the lesson is in `15-learning/`. | REQ-PS-009 |
| REV-027 | minor | `Processes#sessions` | Recognises claude, codex, and grok by executable name (or as the script node or bun runs). A shell installed under another name, or wrapped by a launcher that shows differently in `ps`, is missed. A shell opened in a governed repository for unrelated work is listed. | REQ-PS-009 |
| REV-028 | minor | session phase | The phase and status shown for a session are its change's recorded ones. Records that are not kept current make the list look more precise than it is; the view says what the fields are. | REQ-PS-009 |
| REV-029 | minor | test suite | One of four full runs at this commit failed and could not be attributed (see `06-verification/results.md`). | `.ai/rules/testing.md` |
| REV-002 | minor | `Processes#shell_of` | An unrecognised `--shell` value is reported as the default, `claude`. For a spoof that is wrong, and for a real runner with a typo it would be too (though the runner refuses that). Reporting nothing would be more honest. | REQ-PS-002 |
| REV-003 | minor | `Processes#arguments` | Recognition covers the executable itself and `ruby [flags] soft-foundry`. A wrapper that shows up differently in `ps` (a shell script, `bundle exec` before it execs) is missed while it lasts. | REQ-PS-001 |
| REV-004 | minor | `Processes#recorded_runs` | A run whose runner died is called interrupted. A run in another checkout of the same repository (a second worktree) would also look interrupted from this one, because its process is not "here". | REQ-PS-004 |
| REV-005 | minor | page | A session that finishes between polls disappears without a word; "finished" is only visible as the gate's new state. | REQ-PS-007 |
| REV-006 | minor | `app.js` | Still no automated test that runs the page; this change adds about 110 lines. | `.ai/rules/testing.md` |
| REV-007 | major (evidence gap) | platform | Developed and evaluated on macOS. The Linux paths (`/proc`, procps `ps`) are covered only by one test in CI. Windows is unsupported and the command does not say so; it would report that processes could not be listed. | REQ-PS-001 |

## Conformance
Conforms, with findings. REV-007 should be confirmed on Linux by CI before merge.
