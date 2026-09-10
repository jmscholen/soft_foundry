# Change Intake

## User intent
Define a more rigorous observability standard: when a repository provisions infrastructure as code, it must establish a standard set of metrics and a dashboard equivalent to what an APM tool (New Relic, Datadog) provides out of the box, rather than leaving that to ad hoc discretion.

## Desired outcome
A new, hard-gated maturity capability that:
- Is required for level 5 ("governed") whenever infrastructure-as-code is detected.
- Is satisfied only by a provisioned, dashboard-as-code artifact covering golden-signal/RED/USE metrics for whatever resource types the IaC actually provisions.
- Is exempt (`NOT_APPLICABLE`) for repositories with no IaC, so it never penalizes repositories that have nothing to dashboard.

## Constraints
- Must reuse this control plane's existing NOT_APPLICABLE-is-satisfied scoring mechanism rather than inventing a new one.
- Must not weaken or overload `observability.operational_visibility`, which already has a documented, looser exemption (an in-app operational surface can satisfy it).

## Non-goals
- Not prescribing a specific vendor (Datadog vs. New Relic vs. CloudWatch vs. Grafana) — the standard is tool-agnostic.
- Not adding review-time enforcement on every IaC-touching change (considered and explicitly declined in favor of an assessment-time gate only).

## Task classification
Governance change against `.ai/` (a new maturity capability plus its normative rule definition), per `.ai/skills/learning/SKILL.md`'s standing description of how such proposals are meant to land.

## Initial risk
low — pure policy/documentation content plus one regression test; no change to CLI runtime behavior, no destructive operation, no new production surface.
