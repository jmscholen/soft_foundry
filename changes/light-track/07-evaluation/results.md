# Evaluation Results

Commit SHA: 119e431770bbdddc4048eb625672ee358405fe77

The code tree at this commit is the one verification examined at 4988779; the commit between them records verification only.

Size: `soft-foundry change size --phase evaluate` reported `full_route_sweep` (no scope declared). Every acceptance criterion was run as a journey, and EVAL-010 is the app-wide smoke. There is no sign-in. All commands ran the worktree's code, not the installed gem.

## Journey outcomes
| Journey | Criteria | Tier | Result | Assertions | Evidence |
| --- | --- | --- | --- | --- | --- |
| EVAL-001 | AC-001 | must | pass | 14 of 14 | evidence/EVAL-001.txt |
| EVAL-002 | AC-002 | must | pass | 19 of 19 | evidence/EVAL-002.txt |
| EVAL-003 | AC-003 | must | pass | 9 of 9 | evidence/EVAL-003.txt |
| EVAL-004 | AC-004 | should | pass | 7 of 7 | evidence/EVAL-004.txt |
| EVAL-005 | AC-005 | should | fail | 3 of 5 | evidence/EVAL-005.txt |
| EVAL-006 | AC-006 | should | pass | 3 of 3 | evidence/EVAL-006.txt |
| EVAL-007 | AC-007 | should | fail | 4 of 7; README.md and docs/user/ not evaluated | evidence/EVAL-007.txt |
| EVAL-008 | AC-008 | should | pass | 12 of 12 | evidence/EVAL-008.txt |
| EVAL-009 | AC-009 | should | pass | 11 of 11 | evidence/EVAL-009.txt, evidence/worktree-ci.txt |
| EVAL-010 | AC-001, AC-009 | smoke | pass | 9 of 9 | evidence/EVAL-010.txt |

The three must criteria pass. Two should criteria fail; under the convergence rules a should criterion is reported and does not block.

## What the must journeys showed
- EVAL-001. A record created with `change new --track light` at medium risk was worked and sealed with `phase seal` through intake, specify, implement, verify, review and judge. Each seal moved `current_phase` straight to the next required phase. `gate all` exited 0 before and after the merge with no failing check, the six track-optional phases were pending and skipped, and `change close` closed the record. The same six phases on a gated record: `phase seal specify` exited 2 (`predecessor complete: 01-discovery is pending`), `gate all` exited 2 with only `predecessor complete` failures (discovery, plan, attack pending), and `change close` exited 1. This journey also drives `phase seal` on a light record, which verification noted no test does (VER-003).
- EVAL-002. On a light record and on a gated record, each state failed the same check with exit 2: `must criteria approved`, `specification locked`, and `remediation within cap` (3 rounds, limit 2, no decision). The third reopen was refused on both tracks and the change parked at `awaiting_human`. A light record declared high risk failed `track permitted` ("risk high forces the gated track ... but the change is on light") and `phase seal intake` committed nothing; a gated record at high risk passed that check.
- EVAL-003. With lib/app.rb modified by the change, a review finding marked `outside_change` failed `outside-change findings` with exit 2 for all six spellings, naming the path as written. `lib/other.rb` and `./lib/other.rb` passed.

## Failures
- EVAL-005 (AC-005, should). On a light record whose intake and specification were sealed with `soft-foundry phase seal`, a change to README.md, docs/guide.md, the record and .ai/skills/review/SKILL.md was sized `full_at_verify` with the reason "no scope declared", with and without `--since`. Cause, shown by the control in the same transcript: `phase seal` writes `.soft-foundry/locks/<slug>.lock`; `.soft-foundry/` is ignored by git, and the diff the sizing reads includes ignored paths (`Git#diff_paths` adds the `--ignored=matching` status entries), so `.soft-foundry/` counts as a changed path that is not text. With that directory deleted the same command reported `targeted_plus_full_before_merge` with the documentation-only reason. Any repository where a phase has been sealed or the guard has run has that directory, including this one, so the smaller size is not reached in practice. Verification's probe and the unit test passed because their throwaway repositories never ran a command that creates `.soft-foundry/`. The second half of the criterion holds: a path under lib/ returns `full_at_verify`.
- EVAL-007 (AC-007, should). `soft-foundry help` names the light track only as a value in `--track gated|iterative|light`. It does not name the required phases, the locks kept or the high-risk exclusion. `.ai/workflow.yml` names all of them. This confirms VER-002. README.md and docs/user/ are outside this skill's read set and were not evaluated; review should check them.

## Observations that are not failures
- After `phase seal judge` on a light record, `current_phase` is `learn` and `change status` reads `[status: judged, phase: learn]`, although learning is optional on the light track. The record still gates and closes, and reads `phase: done` once closed (EVAL-001).
- Spellings AC-003 does not list (EVAL-003): `lib/app.rb `, `../outside.rb`, `lib/../../x.rb` and `lib/app.r?` are refused. `LIB/app.rb` and `lib\app.rb` pass as outside the change, as verification noted (VER-004).
- `soft-foundry help` exits 1. The gem installed before this change does the same, so this is not this change's behaviour (EVAL-007).
- `phase seal` prints "note: left uncommitted ... .soft-foundry/" on every seal even though the directory is ignored. Same cause as the EVAL-005 failure; it was present before this change.
- `change status --json` carries `track.name: light` and `skip_reason: track` for a stepped-over phase (EVAL-008, EVAL-010).

## Not swept
`init`, `onboard`, `doctor`, `hooks`, `ui`, `learn`, `update`, `change vet`, `change reopen`, `change release` and `change discharge` were not driven. `soft-foundry ui` renders phase state in a browser and was not opened with a light record.

## Accessibility observations
The surface is command-line output. Markdown heading order of the new documentation is under docs/, outside this skill's read set.
- Keyboard-only operation: pass. Every journey ran from commands and flags with no terminal attached; nothing prompted.
- Outcome in words: pass. Every new or changed line carries its meaning in words: `track: light`, `optional on the light track`, `fail track permitted: risk high forces the gated track ...`, `fail outside-change findings: REV-001 names lib/*.rb, which is not a path inside the repository ...`, `unknown track 'nosuch'; .ai/workflow.yml defines: gated, iterative, light`. Glyphs only accompany `pass`, `fail`, `skip` and `warn`.
- Colour: pass. With `NO_COLOR=1` and no terminal no escape sequence was emitted (EVAL-008).
- Symbols removed: pass. With every non-ASCII character removed, `change status` still shows the track, one phase per line beginning with its directory name, and the label in words (EVAL-008).
- Error identification: pass. The cap refusal, the track conflict, the outside-change refusal and the unknown-track refusal each name the cause and what to do next. One exception: when the documentation-only size is not given (EVAL-005) the reason says "no scope declared" and does not name the path that prevented it.
- Focus order and visible focus: not applicable to line-oriented output.

Evidence generated for a different implementation commit is stale.
