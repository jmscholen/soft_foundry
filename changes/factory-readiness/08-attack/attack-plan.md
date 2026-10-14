# Attack Plan

## Intent to challenge
MIT-001 says the guard protects its own configuration from every skill. After REM-004 that claim rests on a detective and corrective control: `guard` (PreToolUse) records the contents of the policy, the machine-local override and the hook files in `.soft-foundry/guard-baseline.yml`; `guard --after` (PostToolUse, Bash only) restores any that changed and refuses. This fifth attack, at commit 9806b2b (after REM-005 and REM-006), reruns the fourth attack's script to confirm the two fixes (overlapping calls, symlink restore) and to judge which routes remain, as REM-005 asks. Other mitigations (MIT-002 to MIT-007) are untouched by REM-004 to REM-006 (lib diff since 0ed5e0a: guard.rb, cli.rb, hooks.rb only); they are re-checked only through the eval suite and carried forward from the third attack, and the record says so.

## Threats mapped
| Case | Threat | Mitigation attacked |
| --- | --- | --- |
| ATTACK-001 | THREAT-001 | MIT-001 (post-call restore against the spellings that beat the preventive check) |
| ATTACK-002 | THREAT-001 | MIT-001 (attacks on the control itself: baseline, timing, overlap, restore) |
| ATTACK-003 | THREAT-003 | MIT-003 (read side, accepted residual) |
| ATTACK-004 | THREAT-004 | MIT-004 (carried forward) |
| ATTACK-005 | THREAT-005 | MIT-005 (carried forward) |
| ATTACK-006 | THREAT-006 | MIT-006 (eval suite rerun) |
| ATTACK-008 | THREAT-002 | MIT-002 (carried forward) |
| ATTACK-007 | THREAT-007 | MIT-007 (eval output read) |

## Adversarial journeys
Unauthorized journey: an implementation session in block mode tries to leave the guard weaker than it found it. Each case runs the sequence the host runs (pre hook, command, post hook) in a scratch git repository holding a copy of the control plane without the eval cases, a copy of lib/ and exe/, and a change on a change branch at the implement phase. The effect is read back from the files and `Guard.mode`. Script and output are in evidence/.

Abuse cases: the ATK-F8 spellings (quoted cd, out-and-back cd, CDPATH, find -exec, variable, split-name interpreter) plus deletion and override creation, hook-file emptying, removal and creation; a detached process that writes after the post-call check; two overlapping tool calls; a command that rewrites the baseline; a weak policy committed with the baseline deleted; a symlink in place of a hook file; the guard's own code edited through the write tool.

## Safety boundary
Local only; scratch repositories under the system temp directory, removed afterwards; synthetic data; no network, no model provider, no live eval; the real eval cases were not read (denied; the scratch copy omits them); no writes in the checkout outside this phase's directory; destructive actions prohibited. Not exercised: SIGKILL during a case, a live eval session, codex and grok hook payloads, the host's real ordering and concurrency of hook calls (overlap was simulated by calling the hooks in that order).
