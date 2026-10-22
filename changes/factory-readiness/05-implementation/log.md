# Implementation Log

## Changes made
Branch `change/factory-readiness` from `main` 0bd0260 (#48 merged first, on this session's recommendation). Each requirement group is a RED commit holding only its failing tests, then a GREEN commit; verification names the RED commits.

| Group | RED | GREEN | What |
| --- | --- | --- | --- |
| REQ-FR-001 UTF-8 | 4236a75 | d1cb45d | `SoftFoundry.read_text` (`lib/soft_foundry/text.rb`: `binread`, force UTF-8, `scrub`) replaces every content `File.read` in `lib/` (gate, advisory, learning, change record templates, maturity scan, panel, cli, hooks, installer source, session ledger). `test/ui_assets_test.rb` and one `test/content_scan_test.rb` read use it too. |
| REQ-FR-002 lock | 26497a4 | df38249 | `Git#last_commit_for`, `Git#blob`. `Gate#recorded_commit(phase)`: the newest commit touching a phase's handoff while it says complete. `specification_lock_check` on every track: vetted commit when vetted, else the specify phase's recorded commit (warn `not yet locked` until committed), comparing `02-specification/` minus `handoff.yml`. `staleness_check(phase, handoff)` also fails when the lock commit is not an ancestor of the phase's own recorded commit. `test/lifecycle_tracks_test.rb`: the gated-track test now asserts the lock. |
| REQ-FR-003 advisory, REQ-FR-007 waivers | e9908a3 | ddc7ca4 | `Advisory#fresh_context_notices` over every `commit_bound?` phase. `ControlPlane#waivable_by_risk`, `NEVER_WAIVED`. `Gate#waivers_check` on the first phase (`waivers permitted`). `Check#check_waivers`. `ChangeRecord#reached_lifecycle_end?` never treats judge as a waived end; `#judgment_status`. `CLI#change_close` refuses without a completed judgment unless `--force`. `.ai/workflow.yml` `waivable_by_risk`. One sentence in the verification, evaluation, and adversarial-testing SKILL.md. `test/cli_change_close_test.rb`: the lightweight-close test now asserts the refusal and `--force`. `test/phase_runner_test.rb`: the no-advisory assertion scoped to review. |
| REQ-FR-004 block, MIT-001 | 7941a62 | f31e61f, 114d07b | `Guard::SELF_PROTECTED` refused for write tools and shell mentions in every skill. `.ai/policies/enforcement.yml` `guard.mode: block`. The block-mode refusal line names the override's existence. `test/guard_test.rb` and `test/cross_cli_hooks_test.rb`: warn-mode tests set `SOFT_FOUNDRY_GUARD=warn`; mode lines expect block. |
| REQ-FR-005, REQ-FR-006 evals | 277c0d4 | fb747ac | `lib/soft_foundry/harness_eval.rb` (`Case` loading and lint, `Runner` with scratch repositories, gate and live runs, tokens). `CLI#eval_command`, `eval_line`, `eval_counts`, `eval_summary`; `ci` runs the gate cases; `check_harness_evals`. Twelve gate cases and one live case under `.ai/harness-evals/cases/`; `.ai/harness-evals/README.md` rewritten. |
| REQ-FR-008 application repository | 2019018 | 9087f0a | `test/application_repo_test.rb` (Rails-shaped fixture through init, profile, change new, check, guard in block mode, intake gate, eval). RED failed on one assertion: `init` did not ship the cases (`Installer::Source` excluded `.ai/harness-evals/` beyond the README). GREEN ships `cases/`; `test/installer_source_test.rb` and `test/cli_init_test.rb` updated. |
| REQ-FR-010 docs | — | 531a641 | README (new "Proving the gate: harness evals"; guard, gates, tracks, closing sections), `.ai/schemas.md` (checks, advisory, eval case schema), `.ai/README.md`, `AGENTS.md`, help text; `SoftFoundry::VERSION` 0.21.0. |

`soft-foundry eval` in this repository: 12 passed, 0 failed, 0 errors, 1 skipped, in about eleven seconds. `soft-foundry check`: no errors. `soft-foundry scan`: 0 errors, 5 warnings, all in older records quoting attacks.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
No `challenges/` entry. Two things worth a line:

- The first gate run on this record's own discovery phase crashed with `invalid byte sequence in US-ASCII` (an arrow character in `repository-context.md`) in this C-locale container: the live reproduction of REQ-FR-001, fixed by the first GREEN commit.
- The `invisible-text-in-evidence` case first carried a real U+200B, because the tool that wrote the file decoded the backslash-u escape for U+200B before the shell saw it, and `check` refused it as invisible text in the control plane. The runner now builds the character (`${INVISIBLE_ZWSP}`), like the secret canaries, so no case file carries anything the scan refuses.
