# Change Intake

## User intent
Item 7 of the field feedback from an adopter repository (a Rails app using Soft Foundry), the "smaller fixes" that remove friction in everyday use. Change A (scoped verification, items 1-3) and change B (phase lifecycle controls, items 4-6) are merged. The maintainer asked for them to be built generically for any adopter, not around that repository's framework.

## Desired outcome
1. `soft-foundry change new <slug> --type TYPE --risk RISK` records the task type and risk in `metadata.yml` at creation, validated against the allowed values, so they need not be hand-edited after creation.
2. When a phase-run session writes its handoff `complete` while the handoff lists blocking items, the runner sets the handoff to `blocked` itself and says so, instead of leaving the gate to fail afterwards.
3. Skill guidance tells agents how to write payloads that contain invisible or control characters into evidence safely (visible escapes, or escape sequences in scripts), so the content-clean gate does not fail on quoted attack payloads.
4. A per-change latest-state summary: one short view of where a change is now (current phase, each phase's status, the newest finding counts, what blocks it, what is owed) without reading every handoff.
5. A generic parity rule: when a change touches a path the repository profile declares as access control, the verification must run its checks with the protection in force (for example request forgery protection enabled), not only with it disabled for convenience. The rule is declared through repository profile keys and applies to any framework.

## Constraints
- Generic: nothing assumes Rails, a database or any framework. Framework-specific examples belong only in illustrations.
- Existing behaviour, flags and record formats keep working. A record without the new fields stays valid.
- The gate and `ci` keep checking structure, not whether claims are true.
- Soft Foundry's own records must not gain risk from checks that do not apply to this repository; adopters receive the shipped behaviour.

## Non-goals
- Items 1-6 (shipped in changes A and B).
- Anything specific to the adopter repository.
- Writing the `docs/user/` pages and harness-eval cases deferred in change B, except where this change adds its own.

## Task classification
feature, touching the CLI, the phase runner, shipped skill guidance, a rule and the status output.

## Initial risk
medium. No high-risk surface is touched. The CLI output changes, so the accessibility rule applies to the new summary.
