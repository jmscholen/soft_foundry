# Implementation Log

## Changes made
1. RED `eb3ace3`: `test/cross_provider_review_test.rb`: the skill.yml preference and its lint, provider normalization, the runner default (first installed other provider, remediation counted, the no-alternative warning, `--shell` wins, other phases unchanged, unknown provider), the same-provider advisory, `findings explained`, and the template and skill text. 7 failures and 2 errors at RED.
2. GREEN `0370e02`:
   - `.ai/skills/review/skill.yml`, `.ai/skills/final-judgment/skill.yml`: `prefer_different_provider_from: [implement, remediate]`.
   - `.ai/skills/review/SKILL.md`: the failure-it-prevents rule, minor at most without one, defensive additions not blocking or major unless the input is named, and the provider preference.
   - The seven review templates with finding tables gain a "Failure it prevents" column; `.ai/templates/handoff.yml` documents `failure:`.
   - `lib/soft_foundry/phase_provider.rb` (new): shell and name to provider, `PhaseProvider.of(handoff)`.
   - `lib/soft_foundry/phase_runner.rb`: `provider_of` and `default_shell`; `lib/soft_foundry/cli.rb`: `phase run` uses it when `--shell` is absent and prints its line; the `phase` usage text now names grok (REV-FUN-002 from session-ledger).
   - `lib/soft_foundry/advisory.rb`: the same-provider notice; `lib/soft_foundry/gate.rb`: `findings explained` on the review phase; `lib/soft_foundry/check.rb`: the preference names only lifecycle phases.
   - `README.md`, `.ai/schemas.md`, help text; version 0.19.0.
3. Full suite 478 runs, 0 failures, provider keys unset; `check` passes.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
Requiring the runner from the advisory made a load cycle (advisory, runner, gate, change record); provider resolution moved into `PhaseProvider`, which has no dependencies.
