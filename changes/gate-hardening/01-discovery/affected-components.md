# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Gate check list and explanations | `lib/soft_foundry/gate.rb` (`CHECKS` 35-61, `checks_for` 66-79, `evaluate` 91-133) | New checks: structured files parse, test results recorded, commit lineage, criteria covered, manifest verified, verdict recorded, fresh session required; "predecessor complete" tightened to "predecessor recorded" | discovered |
| Commit check | `gate.rb:346-351` | Lineage against the predecessor's `commit_sha` and HEAD | discovered |
| Predecessor check | `gate.rb:356-361` | Requires `recorded_commit(prev)`; message names the sealing command | discovered |
| Judgment outcome parser | `lib/soft_foundry/change_record.rb:292-300` | Reused by the verdict check and by `change close` | discovered |
| `change close` | `lib/soft_foundry/cli.rb:489-553` | Refuse BLOCKED and REJECTED without `--force` | discovered |
| `gate` command exit | `cli.rb:799-808` | Distinct exit for an explicitly named non-complete phase | discovered |
| `phase` subcommands | `cli.rb` (`phase` dispatch near 1064; run paths 1100-1400) | New sealing subcommand; `phase run` and `--parallel` call it | discovered |
| Phase runner | `lib/soft_foundry/phase_runner.rb` (`prompt` 150-166, `begin!` 180-190, `finish!` 194-200) | Prompt no longer says "stop when the handoff is written" without a seal; the runner seals after `finish!` | discovered |
| Parallel run | `lib/soft_foundry/parallel_run.rb`, `cli.rb:1282-1290` | Seal each passed phase in lifecycle order after all sessions return | discovered |
| Scope / change base | `lib/soft_foundry/scope.rb:99-102` | Unchanged code; its precondition (plan recorded) becomes guaranteed | discovered |
| Full-suite record | `lib/soft_foundry/full_suite.rb` | Unchanged; `tests.yml` is now parsed before it is read, so its own YAML rescue paths may become dead | inferred |
| `change new` options | `cli.rb:291-303`, `option` helper | Equals-form `--type=`/`--risk=`/`--track=`; repeated flag | discovered |
| `change summary` | `lib/soft_foundry/change_summary.rb:70-86` | Name a malformed `blocking`/`findings` field instead of `none` | discovered |
| Harness-eval lint and runner | `lib/soft_foundry/harness_eval.rb:158, 255-275, 314-` | Lint accepts the new check names once `CHECKS` has them; cases plant each defect | discovered |
| Harness-eval cases | `.ai/harness-evals/cases/*.yml` | One gate case per new check; the three cases `phase-lifecycle-controls` left owed | discovered (directory denied to this skill; written under the maintainer's override) |
| Skill prompts | `.ai/skills/*/SKILL.md`, `.ai/skills/verification/template/tests.yml`, `final-judgment/template/final.md` | Say that a phase is sealed by the command; template comments name the parse and result checks | inferred |
| Workflow rules | `.ai/workflow.yml` `rules:` | Unchanged keys; the README's description of what each rule means in code is corrected | inferred |
| Test suite | `test/gate_test.rb`, `cli_change_close_test.rb`, `cli_change_new_options_test.rb`, `cli_change_summary_test.rb`, `phase_runner_test.rb`, `phase_run_parallel_test.rb`, `harness_eval_test.rb`, new `phase_complete_test.rb`, `test_helper.rb` (environment isolation) | RED tests for every requirement; `SOFT_FOUNDRY_PHASE` cleared for the whole suite | discovered |
| Fixtures | `test/lifecycle_fixture.rb`, `test_helper.rb#complete_phase!` | `complete_phase!` writes a handoff but does not commit; fixtures that rely on "complete on disk" will need a recorded predecessor | discovered |
| User documentation | `README.md` (sections "Change records and gates", "Fresh-context phases", "Reopening a phase, parallel runs, and released changes", "Proving the gate"), `docs/user/` | New command and checks; the owed pages for the phase-lifecycle commands | discovered |
| Learned rules | `.ai/rules/learned.md` | `learn promote` of the instincts at or above 0.80 | discovered |
| Existing open records | `changes/*/` with status not `closed`/`released` | Must still pass `ci` under the new checks; on this branch that is `gate-hardening` only, and on `main` after merge the same | discovered |
