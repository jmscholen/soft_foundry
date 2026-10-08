# Attack Plan

## Intent to challenge
That a review can carry a serious finding past `findings explained` without naming a failure, or can avoid the same-provider advisory.

## Threats mapped
No threat-model phase (skipped with rationale); the threats are the two named in intake: getting around the new gate check, and silencing the advisory.

## Adversarial journeys
`cases.yml`, run by the real CLI against the evaluation's scratch repository.

## Safety boundary
Local scratch repository; synthetic handoffs; nothing outside the scratch directory touched.
