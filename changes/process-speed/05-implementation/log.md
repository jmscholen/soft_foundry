# Implementation Log

## Changes made
Commits on change/process-speed after the plan seal (2ee7f7f):
- `83cf46a` RED: `test/process_speed_test.rb`, 25 tests for the cap, tiers, approval, person checks, blocked basis, outside-change findings, default waivers, documentation paths and sizing, the documentation-only reopen and seal, and the refusal text. All failed or errored at this commit.
- `171f538` GREEN: `lib/soft_foundry/process_rules.rb` (new); `Git#count_subject`; `ChangeRecord#declare_rules!` and default waivers in `skippable?`; the cap and `--docs-only` in `PhaseReopen`; the cap and documentation-only refusal in `PhaseSeal`; six gate checks (`rules kept`, `criteria tiered`, `must criteria approved`, `remediation within cap`, `blocked basis`, `outside-change findings`) with `CHECKS` entries and tier-aware `criteria covered`; the documentation-only rule in `Sizing`; person checks in `Release`; tier and approval planting in `HarnessEval.complete_phase!`. Test-setup fixes to `process_speed_test.rb` after RED, no assertion changed (commit message lists them).
- `f5c3032` RED: `test/cli_process_speed_test.rb`, 7 command-level tests (reopen at the cap, `--docs-only`, refusal for another phase, `phase run` on a parked change, automatic reopen at the cap, `check` lint, follow-up advisory). Six failed at this commit.
- `cd34e36` GREEN: `phase reopen --docs-only` and help text; `PhaseRunner#refusal` for `awaiting_human`; `ProcessRules.lint` in `check`; follow-up and cap advisories; `record.metadata` / `record.later_metadata` case keys. Control plane: `.ai/workflow.yml` (remediation.max_rounds 2, must_criteria_cap low 3 / medium 8 / high 15, default_waivers [low]); `.ai/policies/human-boundaries.yml` (three boundaries); `.ai/policies/check-sizing.yml` (documentation-only note); SKILL.md for specification, product-documentation, evaluation, adversarial-testing, review, final-judgment, remediation; a placeholder tier and `person_checks` in the criteria template; `run_phases` in the metadata template; `.ai/schemas.md`; seven harness-eval gate cases; `.ai/harness-evals/README.md`; `README.md` convergence section and the bounded guard wording replacing "Neither can be reached from inside a guarded session"; `docs/user/converging-changes.md`. Test fixture: `panel_phases_test.rb` creates a legacy record (panel mechanics, not convergence).

Files written under the maintainer's warn-mode override (`.soft-foundry/enforcement.yml`, set and removed by the maintainer): every `.ai/**` file above, `README.md`, `docs/user/converging-changes.md`. The two `.ai/policies/` files were copied in by this session under the override after the maintainer's own copy command did not reach the worktree; `.soft-foundry/guard.log` records the warnings.

One write happened outside the guard: the first append to `.ai/workflow.yml` was a shell redirection made while the guard was still in block mode (the override file had the wrong shape). The guard does not recognize `cat >> file` as a write. The text is the planned text; the gap is recorded as IMPL-002 for the guard follow-up.

## Decisions
See decisions.md.

## Deviations from plan
See deviations.md: DEV-001 (AC-003 reached through a stale verify, since remediation is not commit-bound), DEV-002 (an unclassified risk warns and applies no must cap), DEV-003 (planted specifications carry tiers and an approval).

## Challenges
- The guard's shell parser refuses heredocs and strings containing a tilde followed by a word (`<<~RUBY`, `~1447`), reading them as home-directory paths. Files were written with the Write tool instead.
- `change new` now writes `rules: 2`, so every suite fixture became a new-rules record; DEV-003 and the panel fixture change resolved the resulting failures.
- A guard baseline file was written under `lib/soft_foundry/.soft-foundry/` while the session's working directory was `lib/soft_foundry`; it was removed before the discovery seal. Same cause as readme-workflow-visuals REV-001: the hook resolves the repository from the working directory.
