# Threat Model

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
Drafts and `ARGUMENT.md` (written by member sessions), the `--panel` and `--max-rounds` values, and the phase's existing record.

## Authorization boundaries
The phase skill's permissions, narrowed per member and stage by the guard (REQ-PN-007).

## Abuse cases
- A member's draft tells the next member to ignore its instructions, edit code, or agree (inter-agent prompt injection).
- A member writes outside its folder, into another member's folder, or into earlier phases' evidence.
- A member forges another member's `agree:` line in `ARGUMENT.md` to end the debate early.
- A crafted `--panel` value or member name reaches a shell command or a path.
- Rounds that never converge run indefinitely and spend without bound.

## Injection / XSS / CSRF / SSRF / file risks
Prompt injection between members (THREAT-001); path injection through member names (THREAT-003); file writes outside the folder (THREAT-002). No network or markup surface.

## Resource exhaustion and DoS
Unbounded rounds or members (THREAT-005).

## Infrastructure exposure
N/A.

## Proposed attack cases
ATTACK-001 a draft carrying instructions to the next member; ATTACK-002 a member writing outside its folder and reading a sibling's in the independent stage (guard); ATTACK-003 a forged `agree:` line under another member's heading; ATTACK-004 `--panel` with unknown shells, five members, `../` names, and `--max-rounds 0` or 100; ATTACK-005 a panel on `implement`.
