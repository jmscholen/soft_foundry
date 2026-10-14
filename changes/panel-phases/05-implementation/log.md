# Implementation Log

## Changes made
1. RED `553030c`: `test/panel_phases_test.rb`, 11 tests: member naming and validation, refusals (implement, `--panel` with `--shell`, `--max-rounds` 0 and 6, one member), the dry run, a full agreeing panel (stage order, environment per launch, resumed sessions, the handoff's `panel:` block and `executed_by`), a split that parks the change, a forged `agree:` line, rewritten argument text, the `panel recorded` gate check, guard narrowing per stage, the `panel_phases` lint and human-boundaries entry, and the single-provider advisory. 11 errors at RED.
2. GREEN `d1cf0d6`:
   - `lib/soft_foundry/panel.rb` (new): members, launches per stage (Claude Code and Grok resume their sessions; Codex starts fresh), prompts that call other members' files data, agreement read only from each member's own appended text, a spoiled round when earlier text changes, the `panel:` block.
   - `lib/soft_foundry/cli.rb`: `phase run --panel`, `--max-rounds`, `--shell-arg SHELL=ARG`, the dry run, the spawner that starts members together with their panel environment, the split handling (`blocked`, `awaiting_human`), help text.
   - `lib/soft_foundry/guard.rb`: `narrow_for_panel` by `SOFT_FOUNDRY_PANEL_MEMBER` and `SOFT_FOUNDRY_PANEL_STAGE`; names the runner does not make are ignored.
   - `lib/soft_foundry/gate.rb`: `panel recorded`. `lib/soft_foundry/advisory.rb`: the single-provider panel notice. `lib/soft_foundry/control_plane.rb`: `panel_phases`. `lib/soft_foundry/check.rb`: the lint.
   - `.ai/workflow.yml` (`panel_phases`), `.ai/policies/human-boundaries.yml` (panel split), `.ai/schemas.md`, `README.md` ("Panels"), version 0.20.0.
3. Full suite 493 runs, 0 failures; `check` passes.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
Headless members need permission flags that differ by shell (Claude Code `--permission-mode`, Grok `--always-approve`), which the shared `-- args` cannot express for a mixed panel. Found while preparing the live evaluation; `--shell-arg SHELL=ARG` was added (deviation 2).
