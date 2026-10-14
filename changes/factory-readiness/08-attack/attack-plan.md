# Attack Plan

## Intent to challenge
The change claims that the guard protects its own configuration from every skill (MIT-001), that eval cases and their contents stay out of an implementer's reach (MIT-003), that eval writes only inside scratch repositories and cleans up (MIT-002, MIT-006), that judgment and review can never be waived (MIT-004), that edits to the specification invalidate evidence (MIT-005), and that eval output never carries planted secrets (MIT-007). This phase tries to make each claim false, at commit ba15a56.

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

## Adversarial journeys
Each case in `cases.yml` records threat, attempted violation, starting privilege, steps, expected safe behavior, observed result, and evidence. The harness is a library, so the attacks call `Guard#decide`, `HarnessEval`, and `Gate` in-process against throwaway scratch repositories (a copy of `.ai/`, a change on a change branch), and use the CLI for `change close` and `eval`. The scripts are kept in `evidence/`.

Unauthorized journeys: implementer to guard configuration; implementer to eval cases; metadata editor to a closed change with no judgment; handoff editor to current evidence for a changed specification; case author to a write outside the scratch directory.

Abuse cases: identifier and path substitution (dot-dot, symlink, glob, cd-relative names, variable and command-substitution indirection), malformed YAML and unsafe tags, oversize input, exception paths, risk and phase spelling.

## Safety boundary
Local only; scratch repositories under the scratchpad and the system temp directory; synthetic data; no network, no model provider, no live eval, no writes outside this phase's directory in the checkout; destructive actions prohibited. Not exercised: SIGKILL during a case, a live eval session, other shells' hook payloads (codex, grok).
