# Attack Results

Commit SHA: 5d36e6f80e14c07928d3b5f1490403b17e01982e

## Authorization envelope
A server this session started on 127.0.0.1:4878, serving a scratch repository of fabricated records, on the maintainer's machine. Loopback only, nothing destructive, nothing third-party. Full envelope in `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-003 | denied | evidence/attack-transcript.log |
| ATTACK-002 | THREAT-001 | denied | evidence/attack-transcript.log |
| ATTACK-003 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-004 | THREAT-005 | denied | evidence/attack-transcript.log |
| ATTACK-005 | THREAT-006 | denied after remediation; violated at 93b9422 | evidence/attack-at-93b9422.log, evidence/attack-transcript.log |
| ATTACK-006 | THREAT-006, THREAT-010 | denied | evidence/attack-transcript.log |
| ATTACK-007 | THREAT-004 | denied | evidence/attack-transcript.log, evidence/hostile-render.log |
| ATTACK-008 | THREAT-009 | denied; error message defect at 93b9422 | evidence/attack-at-93b9422.log, evidence/attack-transcript.log |
| ATTACK-009 | THREAT-007 | denied | evidence/attack-transcript.log |

## Violations found
- ATTACK-005 at `93b9422`: forty silent connections filled the sixteen slots and every real request was answered 503 for up to the 2 s read timeout, repeatably for as long as the attacker kept connecting. Fixed: the longest-idle connection is evicted. Remaining: an attacker connecting faster than requests are read can still race a legitimate connection out; that needs a local process flooding the port.
- ATTACK-008 at `93b9422`: no disclosure, but the error for a non-mapping metadata file was a Ruby message. Fixed.
- One artifact of the first run, not a violation: ATTACK-004's "1 modified files" counted the scratch repository's untracked `changes/` directory; the check was replaced by a before-and-after checksum.

## Blocked cases and reason
None. Not attempted, and stated as limits: a real DNS-rebinding setup with a resolver (the Host check it depends on was tested directly); browsers other than Chrome for ATTACK-007; a second local user account for THREAT-008, which is accepted rather than mitigated.
