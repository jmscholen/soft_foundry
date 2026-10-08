# Security Review

## Scope reviewed

REV-SEC-001 from the session-ledger review: a resume command quoted the folder and pasted `session_id` from the ledger as read. This change's intake limits the fix to re-checking that id and agent on lookup, and quoting the id. REV-SEC-002 and the other minor findings from that review are named non-goals.

Read against `.ai/rules/security.md` (injection, least privilege, no control weakened for convenience) and the intake assumptions: the writer is the same user, because the ledger is mode 0600 in a 0700 directory.

Code: `SessionLedger.trusted?`, `SessionLedger#entries`, `SessionLedger.resume_command`, and every caller that prints or stores a looked-up id (`CLI#sessions`, `CLI#resume`, `Snapshot#recorded_sessions`, `PhaseRunner#recorded_session`, `recordedSection` in `lib/soft_foundry/ui/assets/app.js`). A probe at this worktree called `trusted?` and `resume_command` directly. The new test was re-run. ATTACK-001 and ATTACK-002 were read as claims and agree with the probe; their shell run was not repeated here.

## Findings

None.

## What holds

**Shell breakout on paste.** Lookup will not return an id outside `\A[A-Za-z0-9_-]{1,128}\z` or an agent other than `claude`, `codex`, or `grok`. The agent string is never interpolated; it only selects a fixed command in `RESUME`, and an unknown agent falls back to `claude --resume`. The id is passed through `Shellwords.escape` even when `resume_command` is called with an entry lookup would have refused. Probed:

| Session id | `trusted?` | Quoted in the command |
| --- | --- | --- |
| `x; touch PWNED` | no | backslash before the semicolon and each space |
| command substitution of `id` | no | backslash before `$`, `(`, and `)` |
| a backtick around `id` | no | backslash before the backtick |
| id containing a newline | no | stdlib quote around the line break; lookup does not print it |
| a single quote and a semicolon | no | backslash before the quote, the space, and the semicolon |
| numeric `1` (not a String) | no | not returned by `entries` |
| agent outside the three names | no | command template stays `claude --resume`; the agent text is not inserted |
| `0199-abc`, `good-1` | yes | unchanged, which is correct for that alphabet |

ATTACK-002's observation matches the semicolon row: the stub received one argument and created no file.

**Where the string is shown.** `sessions` text prints the id only inside `resume:`. `--json` emits the filtered entry. The snapshot copies `resume_command` into JSON and the page assigns it with `textContent`, not as HTML. `recorded_session` returns the filtered id into the handoff; `YAML.dump` writes that value. An id that fails `ID` cannot arrive there through lookup.

**Retention.** Failing lines stay in the file. Lookup does not rewrite it. That keeps the person's ledger intact and does not turn the filter into a silent delete.

**Not reopened.** A line that passes `trusted?` is still printed with its `cwd` and prompt fields as stored. `record` strips control characters on write; the read path does not do that again. A same-user edit of an otherwise valid line can still put extra lines or terminal controls into `sessions` output through those fields. The parent review treated that as the same read-back gap and did not file it separately from REV-SEC-001. This change's requirement re-checks the id and the agent only. The intake lists the other session-ledger findings as non-goals. No control from the parent change was turned off.

## Residual

`ID` allows a leading hyphen, and `Shellwords.escape` leaves `--help` and `-rf` unchanged. Both pass `trusted?` and are pasted as the argument after `--resume`. `record` would store the same strings if a hook sent them. This probe did not run `claude`, `codex`, or `grok`, so what those programs do with a flag-shaped argument is not established here. It is not a shell breakout: the shell still runs only the agent binary. Closing it would be a tighter alphabet or an end-of-options marker, which REQ-SQ-001 does not ask for. Recorded as residual risk, not as a miss of this fix.

## Conformance

Conforms. The paste boundary REV-SEC-001 described is closed for shell metacharacters, by filtering on read and by quoting on output. No blocking finding.
