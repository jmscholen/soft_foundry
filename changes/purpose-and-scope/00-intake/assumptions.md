# Assumptions

## Explicit assumptions
- The purpose statement goes at the top of `README.md` and `.ai/README.md`; existing sections stay unless they contradict it.
- "Outside party" covers an unauthenticated visitor, an authenticated user acting beyond their permissions, and another system calling the feature.
- The out-of-scope rule applies to attack and review only. The guard and the specification lock keep working as they do today.
- `surfaces.accessibility` is true because the result is documents a person reads.

## Ambiguities resolved
- Who the attacker is: an outside party using the feature (maintainer, 2026-11-14).
- How far the specification lock goes: lock and detect; no phase hunts for ways around it (maintainer, 2026-11-14).
- Where a person steps in: approves the specification, accepts or rejects the result, decides at the remediation cap (maintainer, 2026-11-14).
- Risk: low (maintainer, 2026-11-14).
- Scope: text first; the light track is a separate change (maintainer, 2026-11-14).

## Ambiguities that block safe progress
None.
