# Attack Results

Third run, after remediation 030b28f (REV-001 transaction order, REV-002 blank discharged_at). Earlier runs: 529e749 fixed ATK-001..003. The remediated cases and every other case were re-driven at the commit below; the earlier run's findings are kept below as history and marked fixed or unchanged.

Commit SHA: 89b40116b816723a93f601a6da454e507f2e693b

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
| ATTACK-006 | THREAT-004 | violated (blank now refused; non-blank hand-edited discharge is unlinted) | evidence/drive3.txt |
| ATTACK-007 | THREAT-006 | denied (fixed; look-alike text still stored, scan clean) | evidence/drive1.txt, drive2.txt, drive11.txt, drive12.txt |
| ATTACK-008 | THREAT-006 | denied | evidence/drive9.txt |
| ATTACK-009 | THREAT-007 | denied (fixed) | evidence/drive4.txt, drive5.txt |
| ATTACK-010 | THREAT-008 | denied (fixed) | evidence/drive6.txt, drive7.txt |
| ATTACK-011 | THREAT-008 | blocked_by_scope | none |
| ATTACK-012 | THREAT-009 | denied | evidence/drive4.txt |
| ATTACK-013 | THREAT-009 | denied | evidence/drive5.txt |
| ATTACK-014 | THREAT-005 | denied | evidence/drive5.txt |
| ATTACK-015 | THREAT-005 | denied | evidence/drive5.txt |
| ATTACK-016 | THREAT-006 | denied | evidence/drive9.txt |
| ATTACK-017 | THREAT-004 | violated (U+00A0 discharged_at; CLI and page disagree) | evidence/drive13.txt |
| ATTACK-018 | THREAT-008 | denied (recovery is manual) | evidence/drive14.txt |

## Re-attack of REV-001 and REV-002 (this run, 89b4011)
- REV-002 holds for blank values. discharged_at of "", " ", tab/newline, false, 0, [] and {} is refused by `check` and `ci` with the item named, counted open by `change status`, and `change close` refuses; null is open; a real discharge of the item still works and the page JSON parses (evidence/drive13.txt).
- ATK-007 (new, minor, hand edit only). `discharged_at: "\u00a0"` (NBSP) passes the new test because Ruby `String#strip` does not remove U+00A0: `check` and `ci` pass, `status` reports 0 open items, `discharge` says already discharged, and `change close` gets as far as the merge check. The page's `item.discharged_at.trim()` does strip U+00A0, so it shows the item open and the timeline lists no discharge. That is the CLI/page disagreement REV-002 set out to remove, reachable only by hand-editing metadata.yml (TB-3); a junk string or bare date likewise counts as discharged.
- REV-001 holds. SIGKILL before rename 1, 2, 3, 6 and 7 of a phase reopen (evidence/drive14.txt, driver scripts/kill_hook.rb): `phase_reopenings` stayed empty every time, so history never records a reset the handoffs do not show. Kills after the first rename leave a prefix of the phases pending; `ci` exits 2, `change status` shows FAIL on the stale phases and `change close` refuses (a required phase is pending). A kill before the metadata rename leaves all six pending and the reopen reason lost.
- ATK-008 (new, informational). After a kill the leftover `<file>.soft-foundry-tmp` makes every retry fail with a message naming the file ("remove it and rerun"); recovery is manual, and kill 7 leaves a metadata temp that will block the next metadata write. Fail-closed, not data loss. `check` still exits 0 and `gate judge` still passes on a half-reset record; only `ci`, `status` and `close` notice.
- Race and text cases re-driven at 89b4011: 14 of 14 release/reopen pairs one winner, four concurrent reopens one history entry (drive6, drive7); invisible-character refusals unchanged (drive1, 2, 11, 12); marker, guard, auto-reopen, parallel, UI and env-secret outcomes identical (exit codes line for line).

## Earlier re-attack (second run, 1ce44de)
- ATK-001 fixed. 14 of 14 simultaneous `change release` / `phase reopen` pairs end with exactly one winner (release exit 0, reopen exit 1 naming the released status); 0 inconsistent records. Four simultaneous reopens: one exit 0, one history entry, in 4 of 4 trials. Release won every time, so reopen-first ordering was not observed head to head.
- ATK-002 fixed. Zero width, bidi, line and paragraph separators, soft hyphen, U+180E and tag characters are refused in `--reason`, `--item` and `--note` before anything is written. 22 character classes tried (evidence/drive12.txt). Characters that are visible but confusable (Cyrillic look-alike, NBSP, Hangul filler, braille blank, variation selector, combining overlay, private use, U+FFFC) are accepted; `scan` stays clean after each, so no gate fails. Residual look-alike risk in the UI timeline, not a gate failure.
- ATK-003 fixed. Mistyped `--env` forms print no part of the value; `--env=NAME=VALUE` is refused with a message that does not echo it. Process title, record and messages clean; the secret reaches only the child environment.
- No new defect found in the changed code (`ChangeRecord#locked`, `Text.free_text!`, `parse_env`). Marker, guard, release/discharge, auto-reopen, parallel refusal and UI cases gave the same outcomes as before.

## Violations found (first run; status now)
1. ATK-001, major, FIXED. `change release` and `phase reopen` (and `phase reopen` against itself) read the record's status and the reset set before they take the record lock, then write under it. Started together on a finished record, both exit 0 in 14 of 14 runs and leave `status: released` with verify through learn all `pending`; `check` and `ci` pass (released records are not re-gated), and the open items can be discharged and the record closed. Four simultaneous reopens all succeed and write four history entries instead of one. Code: `lib/soft_foundry/phase_reopen.rb` (status and reset computed before `@record.transaction`) and `lib/soft_foundry/release.rb` (`refuse_status!`, `judgment!`, `lifecycle!`, `gates!` before `update_metadata`). Contradicts REQ-014 and MIT-007 (reset and status change applied as one serialised write). Reproduction: `evidence/scripts/drive7.rb`.
2. ATK-002, minor, FIXED. `Text.free_text!` refuses only `\p{Cntrl}`. U+202E (bidi override), U+200B (zero width) and U+2028 are accepted, persisted into `metadata.yml` and into the notes of every reset handoff, and then `soft-foundry scan` reports 14 errors and the `content clean` gate fails on each redone phase until its notes are rewritten. A look-alike reason can also reorder displayed text in the UI timeline and `status`. Contradicts MIT-005 as written.
3. ATK-003, minor, FIXED. Credential echo on mistyped `--env`: `--env postgres://u:secretpw@h/db?x=1` (NAME= forgotten) prints the text before the first `=` as the variable name, and `--env=DB_URL=secretinline` prints the whole value in `unknown option(s)`. The `ps` title and the record were clean. Contradicts REQ-012 / MIT-006 ("never in errors").
4. ATK-004, minor, still open (accepted residual). A hand-edited discharge (`discharged_at` set, even to an empty string, with no note or commit) passes `check` and `ci`; nothing distinguishes it from a real discharge, and `change close` does not lint the release block. TB-3 accepts hand edits as detectable only by review, so this is recorded as an observation.
5. ATK-005, informational, unchanged, already documented. A session that runs `env -u SOFT_FOUNDRY_PHASE soft-foundry change release ...` in Bash releases the change (exit 0); the guard checks Bash against deny sets only. A fully forged finished record (all handoffs hand-written complete, placeholder text, no `executed_by`) releases; the only signal is a non-blocking advisory. Both are the residuals the threat model and gate-scope note already state.

## Blocked cases and reason
ATTACK-011 (planted or held lock, symlinked temp file, metadata, handoff and lock directory) was not run. The runtime guard refused the shell command because it named `.soft-foundry`, and rewriting the command to hide the name would have evaded a control that is part of the declared scope. This leaves THREAT-008's lock and symlink mitigations untested by this phase.

## Not covered
The kill-mid-write, symlink, held-lock and signal cases remain unrun (ATTACK-011 is still blocked_by_scope; the kill-mid-write case is now covered by ATTACK-018 for phase reopen only, not for release, discharge or parallel runs). The reopen-first ordering of the release/reopen race was not seen. No browser was driven, so ATTACK-008 rests on the API response and a read of `app.js` for HTML sinks. No live model session ran, so prompt-level misbehavior of a real phase session was not attacked. Kill-mid-write and signal forwarding to parallel children were not exercised. THREAT-010 is accepted residual risk.
