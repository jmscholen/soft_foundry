# Attack Results

Commit SHA: 952808b9f07f1ddc712376123374fecfaebc7db8

## Authorization envelope
A server and scratch repositories this session created on the maintainer's machine, loopback only. Full envelope in `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-002 | THREAT-003 | denied | evidence/attack-transcript.log |
| ATTACK-003 | THREAT-001 | denied | evidence/attack-transcript.log |
| ATTACK-004 | THREAT-004 | denied | evidence/attack-transcript.log |
| ATTACK-005 | THREAT-001 | denied | evidence/attack-transcript.log |

## Violations found
None.

## Blocked cases and reason
None. Not attempted: reading the token from another process of the same user (accepted: such a process can read the terminal or the server's memory); timing the token comparison (it uses a fixed-length constant-time compare, not measured here); rendering the markup-named repository in a browser; filling the registry with many repositories (THREAT-005, accepted).
