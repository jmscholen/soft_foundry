# Architecture Review

## Scope reviewed

`lib/soft_foundry/phase_provider.rb` (new), the `default_shell` addition on `PhaseRunner`, the `prefer_different_provider_from` key on the review and final-judgment skills, and the calls from `CLI#phase`, `Advisory`, and `Check`. Compared with `.ai/rules/architecture.md` and `.ai/rules/general.md`. No new gem.

## Findings

None.

## What was checked

`PhaseProvider` is a leaf module. `Advisory` can ask which provider a handoff names without loading `PhaseRunner`, which loads `Gate`. That split is the decision in `05-implementation/decisions.md`, and it removes the cycle the log describes. `PhaseRunner.provider_of` delegates to it. The skill key is data on the skill that wants the behavior, not a field on the shared `reasoning_high` profile, so other skills that use that profile are unchanged.

The selection bug in REV-FUN-001 is a branch in `default_shell`, not a layering or dependency problem. It is filed on the functional review.

**Control-plane writes, accepted.** Implementation edited `.ai/skills/review/skill.yml`, `.ai/skills/review/SKILL.md`, the review templates, `.ai/skills/final-judgment/skill.yml`, `.ai/templates/handoff.yml`, and `.ai/schemas.md` (`CONTROL_PLANE`, denied to the implementation skill) and `README.md` (no path group). REQ-XP-001, REQ-XP-005, REQ-XP-006, and REQ-XP-007 require those edits, and no skill's write set covers them. The same exception was accepted on `changes/phase-runner` and `changes/session-ledger`. The diff of those files is the preference key, the failure-it-prevents column, the `failure:` note, and the README and schema paragraphs. Nothing else was slipped in. The maintainer still accepts the control-plane edit at merge, as the deviation says.

## Conformance

Conforms. The new module solves a cycle that loading the runner from the advisory demonstrated. The preference lives on the two skills that have it. The control-plane exception above is accepted.
