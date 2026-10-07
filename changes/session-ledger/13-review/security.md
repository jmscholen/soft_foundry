# Security Review

## Scope reviewed

THREAT-001 through THREAT-009 and MIT-001 through MIT-008, checked against the code rather than against the attack write-up alone. Attack results at `93acd89` (all eight cases denied) were read as evidence. Trust boundaries in `03-threat-model/trust-boundaries.md`: hook payload, ledger file, pasted resume commands, terminal and UI rendering, user-level settings, guard decision.

`.ai/rules/security.md`: injection, secret storage, filesystem permissions, least privilege, no weakened control without an exception.

## Findings

| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-SEC-001 | major | `SessionLedger.resume_command`; callers in `CLI#resume`, `CLI#sessions`, `Snapshot#recorded_sessions`, `app.js` `recordedSection` | A resume command shell-quotes the folder and does not quote or re-check the session ID. `resume_command` interpolates `entry['session_id']` raw. `record` refuses an ID that fails `/\A[A-Za-z0-9_-]{1,128}\z/`, and ATTACK-001 confirmed that for hook payloads. Anything already in the ledger is trusted on the way out: `entries` returns every JSON object that has a `session_id`, and `update` rewrites those objects forever. The threat model lists the ledger's existing contents as externally controlled input, and the command is meant to be pasted. A line written by any same-user process (including a coding agent that never went through `record`) such as a session ID of `x; echo PWNED` is printed as `cd <quoted> && claude --resume x; echo PWNED`. The same string is what the page puts on the clipboard line. Other local users cannot write the 0600 file; this is not a cross-user bypass. It is an incomplete paste boundary for a file the product rewrites from disk. | THREAT-001, MIT-001, REQ-SL-009. `.ai/rules/security.md` (injection). Trust boundary "Printed resume commands". |
| REV-SEC-002 | minor | `SessionLedger.default_path`, `SessionLedger#update` | The default path is `~/.soft-foundry/sessions.jsonl`, outside every repository, mode 0700/0600, symlink refused. That meets REQ-SL-004 and ATTACK-004. `SOFT_FOUNDRY_SESSIONS`, when set, is used with no check that it is absolute or outside a repository, and every record `chmod`s the parent directory to 0700 when this user owns it. A relative value names `.`, which for the hook is the project directory: the worktree is mode 0700 and prompt excerpts land inside it, where they can be committed. README documents the variable as an alternate location and does not state that constraint. | REQ-SL-004 (the ledger lives outside every repository). `.ai/rules/security.md` (least privilege on the filesystem). |

## What holds

- **THREAT-001 payload path.** Malformed IDs are not recorded. Folders pass through `Shellwords.escape`. ATTACK-001's `sh -c` of the printed `cd` reached the literal folder and created no extra file. REV-SEC-001 is the readback gap, not a failed payload test.
- **THREAT-002.** Excerpts are flattened, stripped of C0/C1/DEL, masked with `ContentScan::SECRETS`, then cut to 140 characters. Masking runs on the full string before the cut, so a match is not split in half. ATTACK-003: the six shapes were stored as `[masked]`; directory 0700, file 0600. Credentials that match none of those six shapes (a password in a sentence, a bearer token, an AWS secret key) are still stored. That is the specified mask, not a wider promise.
- **THREAT-003.** Control characters are removed from every field `record` writes. ATTACK-002 found no escape or bell bytes in `sessions` output. Characters outside C0/C1/DEL (bidi overrides) are not stripped. The mitigation names C0/C1/DEL only. Output does not re-strip a hand-edited line; that is the same readback trust as REV-SEC-001, not a second finding.
- **THREAT-004 / THREAT-006.** Symlink at the ledger path, the lock, or the directory raises `TargetError` and writes nothing. `O_NOFOLLOW` on the lock and the temp file. Install uses `read_settings` (symlink raises) and `SafeWrite`. A pre-existing 0755 directory and 0644 file were tightened in ATTACK-004. The temp file is renamed over the ledger, so readers see a whole file. A same-user race between close and rename can replace the temp name; the directory is 0700, so that racer is the owner, who can already write the file.
- **THREAT-005.** Stdin is capped at 1 MB. Over that, JSON parse fails, the hook exits 0, and the session is recorded on a later ordinary prompt (FIND-ATK-001, now in README). Corrupt lines are kept. The hook entry's timeout is 10 seconds. `whereabouts` runs `git` with no timeout of its own; a hung `git` can consume that 10 seconds. The bound holds. The ledger is rewritten in full under the lock; CHECK-007 is under a second at 5,000 rows.
- **THREAT-007.** `el` sets `textContent` or a text node. `app.js` has no HTML parser. The phase link is `encodeURIComponent` into a hash route. The UI listens on `127.0.0.1` and requires the token. ATTACK-007's markup was stored and rendered as text. Absolute paths and prompt excerpts on that page are the recorded decision in `05-implementation/decisions.md` (loopback, token, the person's own machine).
- **THREAT-008.** The four Grok names take the same decisions as the Claude Code tools, including a CLI payload in block mode. `edit_file` and any future name remain "not guarded". That residual is TM-001, confirmed by ATTACK-006, and is not closed by this change. It is not a silent weakening of a tool the change claimed to map.
- **THREAT-009.** `flock` on a sibling lock is held from read through rename. ATTACK-008 kept 50 of 50 rows and left no temp files. The unit test covers 20.

`session_log` discards stdout and stderr in the hook command as well as inside Ruby, and exits 0. That fail-open is the requirement, not a disabled control. The guard was not put into a weaker mode.

Codex's user hook file format and the runner's Codex lookup were not exercised live (Codex login expired, EVAL-006). Tests use the documented payload. That limit is already in verification and evaluation; it is residual, not a new defect found here.

## Conformance

Conforms with advisories. The payload, permission, masking, and symlink controls specified for this change are present and were attacked. REV-SEC-001 should be fixed or explicitly accepted: quote the session ID and refuse to print a command whose ID fails `SessionLedger::ID`. REV-SEC-002 should be fixed or explicitly accepted: reject a relative override and a path inside a repository, and do not `chmod` an unrelated parent.
