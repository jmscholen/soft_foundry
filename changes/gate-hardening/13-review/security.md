# Security Review

## Scope reviewed
`surfaces.security: true`. Reviewed against 03-threat-model and 08-attack: symlink refusal (`RecordFile`, REQ-034), explicit-path staging (REQ-033), `CLEAN_ENV` clearing of hook-exported git variables, manifest path containment, no network or credential reads (REQ-035), and the forged-record routes the attack phase tried (ATTACK-001 to ATTACK-029). No secrets or raw hidden characters were found in the phase evidence read.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `change_record.rb` `recorded_commit` | Seal identity is a commit subject (see functional.md REV-001 and ATK-014). The forged subject makes a hand-committed handoff the record. | A committer forges `Record <slug> <phase>` on a handoff-only commit; stale evidence passes the gate after a code change. Weakens the integrity claim of THREAT-001 for a deliberate committer; equals the pre-change baseline. Suggested fix: bind the seal to something only the tool writes (a commit trailer, or require the moving commit_sha to follow a phase_reopenings entry whose evidence changed). | THREAT-001, REQ-009 |
| REV-007 | minor | `control_plane.rb` `enforcement_mode`, `check.rb` (ATK-016) | A scalar `guard: block` in `policies/enforcement.yml` aborts gate, seal and check with `String does not have #dig method` and no file name; `mode: block` at the top level and `guard: {}` read as warn silently. | A maintainer who writes `mode: block` believes the fresh-session requirement is on; `fresh session recorded` skips and a review completed without `executed_by` passes. | REQ-014, THREAT-008 |

## Conformance
Conforms with advisories. No new trust boundary, network call or credential read. The gate remains structural: a committer can still edit any file, which the specification states; REV-001 is the open route where that edit is cheap.
