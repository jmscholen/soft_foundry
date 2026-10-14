# Attack Plan

## Intent to challenge
The change claims that the guard protects its own configuration from every skill (MIT-001), that eval cases and their contents stay out of an implementer's reach (MIT-003), that eval writes only inside scratch repositories and cleans up (MIT-002, MIT-006), that judgment and review can never be waived (MIT-004), that edits to the specification invalidate evidence (MIT-005), and that eval output never carries planted secrets (MIT-007). This is a re-attack at commit fe9e40d0a820eba58770daa593d4c9a7a26ea206, after REM-002 changed the guard (cd-following, glob expansion, symlink resolution, whole `.soft-foundry/` directory, case size cap). The first attack (ba15a56) found ATK-F1 to ATK-F4; this phase first replays those routes, then attacks the new code.

## Threats mapped
| Case | Threat | Mitigation attacked |
| --- | --- | --- |
| ATTACK-001 | THREAT-001 | MIT-001 |
| ATTACK-002 | THREAT-002 | MIT-002 |
| ATTACK-003 | THREAT-003 | MIT-003 |
| ATTACK-004 | THREAT-004 | MIT-004 |
| ATTACK-005 | THREAT-005 | MIT-005 |
| ATTACK-006 | THREAT-006 | MIT-006 |
| ATTACK-007 | THREAT-007 | MIT-007 |
| ATTACK-008 | THREAT-001 | MIT-001 (the guard's own failure mode) |

## Adversarial journeys
Each case in `cases.yml` records threat, attempted violation, starting privilege, steps, expected safe behavior, observed result, and evidence. The attacks call `Guard#decide`, the hook entry point (`soft-foundry guard`, JSON on stdin), `HarnessEval`, and `Gate` against throwaway scratch repositories (a copy of `.ai/`, a change on a change branch at the implement phase), plus the `eval` and `change close` CLI commands. Scripts are kept in `evidence/`.

Unauthorized journeys: implementer to guard configuration; implementer to eval cases; metadata editor to a closed change with no judgment; handoff editor to current evidence for a changed specification; case author to a write outside the scratch directory; implementer to a guard that crashes.

Abuse cases: path substitution (dot-dot, chained `cd`, `cd ..` back to the root, symlink, glob, brace expansion, variable and command-substitution indirection, `~user`, `~+`, NUL byte), malformed YAML and unsafe tags, oversize and aggregate input, exception paths, risk and phase spelling.

## Safety boundary
Local only; scratch repositories under the system temp directory, removed afterwards; synthetic data; no network, no model provider, no live eval; no writes in the checkout outside this phase's directory; destructive actions prohibited. Not exercised: SIGKILL during a case, a live eval session, other shells' hook payloads (codex, grok), the real host's handling of a hook that exits 1 beyond one harmless `echo` probe.
