# Assumptions

## Explicit assumptions
- "Two rounds" counts completed remediation phases of one change since its specification locked; a remediation reopened by a person's recorded decision starts a fresh allowance. Discovery confirms how `phase_reopenings` and `Record <slug> remediate` commits can be counted.
- The cap on `must` criteria by risk is set in policy, not code. Starting values for specification to confirm or change: low 3, medium 8, high 15.
- The `must`-list approval is a `human_decisions` entry (a new boundary name), so it reuses the existing parking and recording mechanism instead of adding a new one.
- "Only documentation" is decided from the diff against declared path groups (`DOCS`, `README.md`, the change record), the same way `change size` decides today, never by judgment.
- Existing records without tiers stay valid: an untiered criterion is treated as `must` for records created before this change, so nothing already sealed changes outcome.

## Ambiguities resolved
- Risk: high (maintainer, 2026-11-13).
- Scope: all four groups proposed in the analysis go into this change (maintainer, 2026-11-13).
- Cap: two remediation rounds; a third needs a person's recorded decision (maintainer, 2026-11-13).
- Approval to loosen blocking controls: given and recorded (maintainer, 2026-11-13).
- The check catalog is a separate, later change.

## Ambiguities that block safe progress
None.
