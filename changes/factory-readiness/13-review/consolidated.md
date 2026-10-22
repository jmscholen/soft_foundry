# Consolidated Review

Commit reviewed: a9fac32d0c0e2d8951ee09ed0a5c9a8102c34637 (application code identical to ac3e8cf; verification 568 runs, 0 failures, evaluation and attack rerun after REM-006).

## Verdict
No blocking findings. Two major findings need the maintainer's attention before merge; both are decisions or text, not code defects that a rerun of verify would fix.

| ID | Severity | Summary |
| --- | --- | --- |
| REV-001 | major | Documentation and installation owed since REM-001 to REM-006 are still not applied (README guard section, `enforcement.yml` comment, this repository's hook settings); until `hooks install --claude` is rerun the post-call restore and search-tool guard are inactive. |
| REV-002 | major | Same-user routes past the post-call restore (ATK-F10 remainder) remain; accepted residual, needs an explicit judgment decision. |
| REV-003 | minor | Root-wide reads reach the eval cases (ATK-F9, accepted). |
| REV-004 | minor | PostToolUse on a failing Bash call is unverified. |
| REV-005 | minor | Guard code is in the implementer's write set when dogfooding. |
| REV-006 | minor | Rails profile records `ruby`, not rspec. |
| REV-007 | minor | Default live eval needs shell arguments; undocumented. |
| REV-008 | minor | `commit_sha` self-attested. |
| REV-009 | minor | Accessibility advisory: error suggestion for the live eval failure. |
| REV-010 | minor | README understates the guard's protection. |
| REV-011 | minor | Edit within 30 minutes of an interrupted shell call is reverted. |

## Unresolved findings
All of the above are open at review; none is fixed by this phase. Nothing returns to verify: no finding requires an implementation change to meet a requirement. REV-001 is owed to the maintainer outside every skill's write set; REV-002 and the carried residuals are for judgment.

## Go-live advisories
Accessibility (REV-009). Policy: none owed. Observability: `12-observability` is pending, not waived; it is a CLI with `surfaces.observability: false`, and judgment should note it.
