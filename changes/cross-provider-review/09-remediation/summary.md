# Remediation

## Finding references
- **FIND-ATK-001 (major), from 08-attack.** `findings explained` checked only findings whose severity was spelled `blocking` or `major`. A review that called a serious finding `critical` or `high` (or gave no severity) passed with no failure named.

## Root cause
The check listed the severities that need a failure instead of the one that does not. The templates offer three words, but a reviewer (or an agent) can write any word, and a check that trusts the vocabulary is bypassed by changing it.

## Changes made
- RED `e62bc6e`: `test_any_severity_but_minor_must_name_its_failure` (critical, High, and a missing severity fail; Minor passes). The same commit reopened 06, 07, and 08 (handoffs to `in_progress`).
- GREEN: `lib/soft_foundry/gate.rb` requires `failure:` on every finding whose severity is not `minor` (case and surrounding spaces ignored); the check's messages say "above minor". The same rule is now stated in `.ai/skills/review/SKILL.md`, `.ai/templates/handoff.yml`, `.ai/schemas.md`, and `README.md`.
- Requirement effect: REQ-XP-005 is strengthened from "blocking or major" to "every severity except minor"; nothing it already required is relaxed.

## Evidence invalidated
Verification, evaluation, and attack evidence at 0370e02.

## Required reruns
Verification, evaluation, and attack, all at the remediated commit; ATTACK-001 must now deny the `critical` case.
