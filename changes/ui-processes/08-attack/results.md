# Attack Results

Commit SHA: dd18466001ecc7246f8266643a154bcdc1ff0ff5

## Authorization envelope
Processes and a loopback server this session started in scratch directories on the maintainer's machine. Full envelope in `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | denied | evidence/attack-transcript.log |
| ATTACK-002 | THREAT-002, THREAT-003 | denied | evidence/attack-transcript.log |
| ATTACK-003 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-004 | THREAT-001, THREAT-004 | denied | evidence/attack-transcript.log |
| ATTACK-005 | THREAT-001 | denied | evidence/attack-transcript.log |

## Violations found
None. One thing that is not a violation and is worth knowing: a process started as a ruby script named soft-foundry is listed (ATTACK-001), with nothing but its command. THREAT-004 accepts this.

## Blocked cases and reason
None. Not attempted: a hostile record in another repository against a live server (covered by a unit test: markup in `status` and `current_phase` is dropped, and an unreadable record leaves the change name only); a working directory with hostile characters in its name (the path is rendered as text, and that rendering was attacked in ui-server); a very large number of processes.
