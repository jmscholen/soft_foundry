# Security Review

## Scope reviewed

Loaded `.ai/rules/security.md` and the threat model (`03-threat-model/threats.yml`, `mitigations.md`, `trust-boundaries.md`). Checked the session marker, guard marker parsing, `--env` handling, free-text validation, the record lock, release preconditions, and the third attack at `89b4011`. Code at `2be4aff` matches that attack's tree for `lib/` and `test/`.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-009 | minor | `ChangeRecord.discharged?`; `Release.lint`; `ui/assets/app.js` `releaseSection` | A hand-edited `discharged_at` of only U+00A0 passes `check` and `ci` and counts as discharged in Ruby, including the close confirmation for a judgment-carried item. The page shows the same item as open. ASCII blanks are refused (the previous REV-002). A non-blank junk string is discharged on every surface. That junk-string case stays the accepted TB-3 residual (ATK-004). U+00A0 is filed because the surfaces disagree. | Set `discharged_at` to a lone U+00A0. `ci` and `change status` report no open items. The released table says open. `change close` treats a `from: judgment` item as confirmed. | REQ-018, REQ-019, MIT-003, `.ai/rules/security.md` (do not trust a record field without a check that matches every consumer) |

## Checked and holding

- Marker refusal. `phase reopen`, `change release`, and `change discharge` refuse when `SOFT_FOUNDRY_PHASE` is set, including when it is set to an empty string (`env.key?`). Auto-reopen uses `source: auto` and skips that check, and it runs before the session starts. The guard resolves the skill from the marker. An unknown, empty, or non-isolated marker during `SOFT_FOUNDRY_PARALLEL=1` is a violation rather than a silent fallback (MIT-002). Attack ATTACK-001 and ATTACK-003 were denied.
- Marker bypass. Unsetting the variable in a shell still releases the change (ATK-005, TB-1). Documented in `README.md` and `.ai/schemas.md` as a guard against accident, not a sandbox. Accepted residual. Not a new defect.
- `--env`. Names match `[A-Z_][A-Z0-9_]*` and cannot start with `SOFT_FOUNDRY_`. Values go through `Process.spawn`'s environment hash. `parse_env` echoes a name only when it is a short identifier, and `--env=NAME=VALUE` is refused before `parse_env`, with a message that does not contain the value (ATK-003 fixed). `ParallelRun#redact` strips values from spawn errors. `Process.setproctitle` masks `--env NAME=VALUE` after parsing. The remaining window and the shell history are deviation D6, accepted: the value has to be on the command the person typed, and the child environment is the specified channel (TB-5, MIT-006).
- Free text. `Text.free_text!` refuses controls and format, line, and paragraph separators, capped at 500 characters, and the record is YAML-emitted. Look-alike letters that are visible still pass (ATK-002 residual). The content scan stays clean. Accepted as a display residual, not a gate bypass.
- Release preconditions. Release requires a releasable status, one approving judgment word, lifecycle end, no failing gate, and at least one item. Judgment undischarged ids are carried. The check-then-write for release and reopen holds the record lock across the decision and the write (ATK-001 not reproduced at `89b4011`: 14 of 14 pairs, one winner; four concurrent reopens, one history entry).
- Lock and crash. `flock` with a 10 second bound, `O_NOFOLLOW`, and a reentrant thread-local hold. Staging a write removes temps it created when staging itself raises, and the record stays byte-identical. A raise or kill during the rename loop is REV-008: fail-closed for `change close`, history never ahead of the handoffs (ATTACK-018, drive14). ATTACK-011 (held lock, symlinked lock and temp, kill mid-write for release and discharge) was not run. The guard refused shell commands that named the lock directory. THREAT-008's symlink cases stay unverified by attack.

## Conformance

Conforms with REV-009, plus the accepted residuals named above (marker unset, D6 process title and shell history, look-alike text, hand-edited non-blank discharge timestamps, adopter-owned isolation when `--env` is omitted). No security control was turned off to make a test pass. The previous REV-002 (ASCII-blank `discharged_at` discharged in Ruby, open in the page, and accepted by lint) does not reproduce.
