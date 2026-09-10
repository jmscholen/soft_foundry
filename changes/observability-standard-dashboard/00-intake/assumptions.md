# Assumptions

## Explicit assumptions
- "Rigorous observability framework" means a maturity-gate-enforced standard, not merely advisory text — confirmed with the user (chose "new maturity capability" over "review-time rule only" or "both").
- The metric baseline is the industry-standard Golden Signals + RED/USE combination — confirmed with the user over "minimal APM parity" and "user-specified list."
- This change is performed directly by the interactive session, not a fresh-context agent per phase, given its scope (two policy files plus one regression test) — the same deliberately lighter-weight process used by `self-update` and `maturity-report`.

## Ambiguities resolved
- Whether the new capability should live inside the existing `observability.alerting`/`operational_visibility` capabilities or as a new one: resolved as a new capability (`observability.standard_dashboard`), because the two existing capabilities already have documented, looser semantics (an in-app page can satisfy `operational_visibility`; general alerting existence satisfies `alerting`) that a stricter IaC-specific requirement would otherwise silently override.
- Whether to gate on the whole `production_service` bucket or add an IaC-specific bucket: resolved as a separate `capability_guidance.observability.infrastructure_as_code` bucket, since the existing `production_service.conditional` bucket's items are contextual guidance, not required-for-scoring, and this change specifically needed a hard requirement tied to the presence of IaC.

## Ambiguities that block safe progress
None.
