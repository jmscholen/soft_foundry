# Attack Results

Commit SHA: 3e356a192053aea57572f94afa3a15d7563ee647

## Authorization envelope
Local scratch clone under /tmp, synthetic data, no network or provider calls, destructive actions prohibited. Only files under changes/small-process-fixes/08-attack/ were written in the real worktree. Size: `change size --phase attack` = full_route_sweep (no declared scope); the change has no routes, so the five CLI and gate doors were all attacked. Control-character payloads are shown as visible escapes.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | denied | evidence/change-new-and-summary-paths.txt |
| ATTACK-002 | THREAT-002 | denied | evidence/summary-hostile-handoffs.txt |
| ATTACK-003 | THREAT-003 | denied | evidence/mark-blocked-shapes.txt |
| ATTACK-004 | THREAT-004 | denied | evidence/mark-blocked-concurrency.txt |
| ATTACK-005 | THREAT-005 | violated (low) | evidence/summary-shape-hiding.txt, evidence/gate-on-blocking-shapes.txt |
| ATTACK-006 | THREAT-006 | denied | evidence/protection-shapes.txt |
| ATTACK-007 | THREAT-007 | violated (low) | evidence/access-control-globs.txt |
| ATTACK-008 | THREAT-001 | violated (low) | evidence/summary-symlink.txt |
| ATTACK-009 | THREAT-009 | denied | evidence/content-clean-guidance.txt |
| ATTACK-010 | THREAT-008 | violated (low) | evidence/change-new-and-summary-paths.txt |
| ATTACK-011 | THREAT-010 | denied | evidence/summary-hostile-handoffs.txt |
| ATTACK-012 | THREAT-005 | violated (low) | evidence/parallel-exit-edges.txt, evidence/parallel-run-tests-at-head.txt |

## Violations found
All low severity; none lets a blocker pass the gate or lowers a risk. Not repaired here.
1. Summary hides a blocker whose `blocking` (or `findings`) is a string or mapping instead of a list: it prints `blocking: none`, while the phase line says blocked. The runner likewise does not mark complete+string blocking blocked; the gate still fails it.
2. An `access_control` glob containing a zero-width or other format character passes the lint and never matches, so paths named by it escape the parity check.
3. `change summary` follows a symlinked handoff.yml or metadata.yml and echoes fields from a file outside the record.
4. `change new` ignores `--risk=low` style (equals form) options and silently drops a repeated `--type`, leaving the template placeholder with no message.

5. A parallel run whose session writes `status: blocked` itself prints `phase <id>: fail` but exits 0 (blocked is a gate warning). Same rule as the single-phase path; the remediation of REV-001 closed only the complete-with-blocking case, which now exits 2.

## Rerun at this commit
The earlier pass ran at 821f1e8. The only code change since is `parallel_run` in cli.rb (REV-001 remediation). At 3e356a1 the CLI doors (ATTACK-001, -002, -005, -008, -010) and the glob lint (ATTACK-007) were rerun in a fresh scratch clone with the same outcomes (evidence/rerun-*.txt); the new exit-status path was attacked as ATTACK-012. Evidence from the other cases was produced at 821f1e8 and their code paths are unchanged (`git diff 821f1e8 HEAD -- lib` is cli.rb parallel_run only). The zero-width glob in rerun-access-control-globs-at-head.txt shows as `?` after ASCII encoding; no raw hidden character is in the evidence.

## Accepted limits observed (not violations)
`protection stated` passes boilerplate notes, a list-valued note, and `in_force` on a failed check: structure only, as specified. The runner's handoff rewrite drops YAML comments. The slug rule (unchanged) allows `.` and `/` segments such as `a/./b`, staying inside changes/.

## Blocked cases and reason
None. No model refusal.
