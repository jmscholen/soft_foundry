# Change Intake

## User intent
After PR #15 recorded this repository's security policy as MISSING under `policies:` in `.ai/repository.yml` (review finding REV-018), the maintainer said: "we dont need a security file for this repository as its a tool not a repo for collecting and processing user information".

## Desired outcome
- **REQ-SEC-001.** `.ai/repository.yml` records `policies.security` as NOT_APPLICABLE with the maintainer's rationale, dated and pointing at this record, so the profile states a decision rather than an open gap. Nothing else changes.

## Constraints
- The profile must still say plainly that no SECURITY.md exists and where a vulnerability report would go (the public GitHub repository), so a reader is not misled into thinking a document exists.
- `soft-foundry check` and `ci` pass unchanged.

## Non-goals
- Adding a SECURITY.md.
- Changing the standard: `.ai/rules/policy-conformance.md` still treats a published security policy as a document to record, and NOT_APPLICABLE still requires a rationale, which this record supplies.

## Task classification
docs: one evidence line in the repository profile.

## Initial risk
low.
