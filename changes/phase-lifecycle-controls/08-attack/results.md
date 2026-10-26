# Attack Results

Commit SHA: 0af7da5ab3108db454fab80b351e13841e6575c6

## Authorization envelope
Local, throwaway clone and fixtures of the tool's own code; authorized by the person who ran `soft-foundry phase run attack`; no network, no live model session, no real repository state touched; destructive actions prohibited and none taken. Full envelope in `cases.yml`. Size: `full_route_sweep`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | denied | evidence/drive1.txt |
| ATTACK-002 | THREAT-002 | violated (documented residual) | evidence/drive10.txt, drive8.txt |
| ATTACK-003 | THREAT-003 | denied | evidence/drive8.txt |
| ATTACK-004 | THREAT-004 | violated (known gate-scope limit; advisory only) | evidence/drive3.txt |
| ATTACK-005 | THREAT-004 | denied | evidence/drive3.txt |
| ATTACK-006 | THREAT-004 | violated (hand-edited discharge is unlinted) | evidence/drive3.txt |
| ATTACK-007 | THREAT-006 | violated (bidi, zero-width, U+2028 accepted) | evidence/drive1.txt, drive2.txt, drive11.txt |
| ATTACK-008 | THREAT-006 | denied | evidence/drive9.txt |
| ATTACK-009 | THREAT-007 | violated (credential echoed on two mistyped forms) | evidence/drive4.txt, drive5.txt |
| ATTACK-010 | THREAT-008 | violated (check-then-write race) | evidence/drive6.txt, drive7.txt |
| ATTACK-011 | THREAT-008 | blocked_by_scope | none |
| ATTACK-012 | THREAT-009 | denied | evidence/drive4.txt |
| ATTACK-013 | THREAT-009 | denied | evidence/drive5.txt |
| ATTACK-014 | THREAT-005 | denied | evidence/drive5.txt |
| ATTACK-015 | THREAT-005 | denied | evidence/drive5.txt |
| ATTACK-016 | THREAT-006 | denied | evidence/drive9.txt |

## Violations found
1. ATK-001, major. `change release` and `phase reopen` (and `phase reopen` against itself) read the record's status and the reset set before they take the record lock, then write under it. Started together on a finished record, both exit 0 in 14 of 14 runs and leave `status: released` with verify through learn all `pending`; `check` and `ci` pass (released records are not re-gated), and the open items can be discharged and the record closed. Four simultaneous reopens all succeed and write four history entries instead of one. Code: `lib/soft_foundry/phase_reopen.rb` (status and reset computed before `@record.transaction`) and `lib/soft_foundry/release.rb` (`refuse_status!`, `judgment!`, `lifecycle!`, `gates!` before `update_metadata`). Contradicts REQ-014 and MIT-007 (reset and status change applied as one serialised write). Reproduction: `evidence/scripts/drive7.rb`.
2. ATK-002, minor. `Text.free_text!` refuses only `\p{Cntrl}`. U+202E (bidi override), U+200B (zero width) and U+2028 are accepted, persisted into `metadata.yml` and into the notes of every reset handoff, and then `soft-foundry scan` reports 14 errors and the `content clean` gate fails on each redone phase until its notes are rewritten. A look-alike reason can also reorder displayed text in the UI timeline and `status`. Contradicts MIT-005 as written.
3. ATK-003, minor. Credential echo on mistyped `--env`: `--env postgres://u:secretpw@h/db?x=1` (NAME= forgotten) prints the text before the first `=` as the variable name, and `--env=DB_URL=secretinline` prints the whole value in `unknown option(s)`. The `ps` title and the record were clean. Contradicts REQ-012 / MIT-006 ("never in errors").
4. ATK-004, minor. A hand-edited discharge (`discharged_at` set, even to an empty string, with no note or commit) passes `check` and `ci`; nothing distinguishes it from a real discharge, and `change close` does not lint the release block. TB-3 accepts hand edits as detectable only by review, so this is recorded as an observation.
5. ATK-005, informational, already documented. A session that runs `env -u SOFT_FOUNDRY_PHASE soft-foundry change release ...` in Bash releases the change (exit 0); the guard checks Bash against deny sets only. A fully forged finished record (all handoffs hand-written complete, placeholder text, no `executed_by`) releases; the only signal is a non-blocking advisory. Both are the residuals the threat model and gate-scope note already state.

## Blocked cases and reason
ATTACK-011 (planted or held lock, symlinked temp file, metadata, handoff and lock directory) was not run. The runtime guard refused the shell command because it named `.soft-foundry`, and rewriting the command to hide the name would have evaded a control that is part of the declared scope. This leaves THREAT-008's lock and symlink mitigations untested by this phase.

## Not covered
No browser was driven, so ATTACK-008 rests on the API response and a read of `app.js` for HTML sinks. No live model session ran, so prompt-level misbehavior of a real phase session was not attacked. Kill-mid-write and signal forwarding to parallel children were not exercised. THREAT-010 is accepted residual risk.
