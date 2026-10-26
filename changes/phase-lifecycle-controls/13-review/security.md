# Security Review

## Scope reviewed

Loaded `.ai/rules/security.md` and the threat model (`03-threat-model/threats.yml`, `mitigations.md`, `trust-boundaries.md`). Checked the session marker, guard marker parsing, `--env` handling, free-text validation, the record lock, release preconditions, and the second attack's results at `1ce44de`.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | major | `ChangeRecord#open_release_items`, `Release.lint`, `ui/assets/app.js` `releaseSection` | Empty `discharged_at` passes `check` and counts as discharged in Ruby, including the close confirmation for a judgment-carried item. The UI shows the same item as open. ATK-004 already recorded the lint gap under TB-3. The two presentations now disagree, so the gap is not only "a committer can lie with a real timestamp." | Set `discharged_at` to an empty string. `ci` and `change status` report no open items. The released table says open. `change close` treats a `from: judgment` item as confirmed. | REQ-018, REQ-019, REQ-020, MIT-003, `.ai/rules/security.md` (do not trust a record field without a check that matches every consumer) |

## Checked and holding

- Marker refusal. `phase reopen`, `change release`, and `change discharge` refuse when `SOFT_FOUNDRY_PHASE` is set, including when it is set to an empty string (`env.key?`). Auto-reopen uses `source: auto` and skips that check, and it runs before the session starts. The guard resolves the skill from the marker, and an unknown, empty, or non-isolated marker during `SOFT_FOUNDRY_PARALLEL=1` is a violation rather than a silent fallback (MIT-002). Attack ATTACK-001 and ATTACK-003 were denied.
- Marker bypass. Unsetting the variable in a shell still releases the change (ATK-005, TB-1). Documented in `README.md` and `.ai/schemas.md` as a guard against accident, not a sandbox. Accepted residual. Not a new defect.
- `--env`. Names match `[A-Z_][A-Z0-9_]*` and cannot start with `SOFT_FOUNDRY_`. Values go through `Process.spawn`'s environment hash. `parse_env` echoes a name only when it is a short identifier, and `--env=NAME=VALUE` is refused without the value in the message (ATK-003 fixed). `ParallelRun#redact` strips values from spawn errors. `Process.setproctitle` masks `--env NAME=VALUE` after parsing. The remaining window and the shell history are deviation D6, accepted: the value has to be on the command the person typed, and the child environment is the specified channel (TB-5, MIT-006).
- Free text. `Text.free_text!` refuses controls and format/line/paragraph separators, capped at 500 characters, and the record is YAML-emitted. Look-alike letters that are visible still pass (ATK-002 residual). The content scan stays clean. Accepted as a display residual, not a gate bypass.
- Release preconditions. Release requires a releasable status, one approving judgment word, lifecycle end, no failing gate, and at least one item. Judgment undischarged ids are carried. The check-then-write for release and reopen now holds the record lock across the decision and the write (ATK-001 not reproduced, 14 of 14 pairs, one winner).
- Lock. `flock` with a 10 second bound, `O_NOFOLLOW`, and a reentrant thread-local hold. Two processes updating metadata did not lose entries (`test_two_processes_updating_the_same_record_lose_nothing`). ATTACK-011 (held lock, symlinked lock, kill mid-write) was not run; the guard refused those shell commands. THREAT-008's symlink cases stay unverified by attack. REV-001 is the kill-between-renames case this review did trace in the source.

## Conformance

Conforms with REV-002, plus the accepted residuals named above (marker unset, D6 process title and shell history, look-alike text, adopter-owned isolation when `--env` is omitted). No security control was turned off to make a test pass.
