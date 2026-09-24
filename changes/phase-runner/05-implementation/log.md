# Implementation Log

## Changes made
- `lib/soft_foundry/phase_runner.rb` (new): `refusal` (exploring, closed or judged, already complete, predecessor incomplete), `prompt`, `launch` (per-shell argument builders for `claude -p` and `codex exec`), `begin!` (current_phase, pending to in_progress, `executed_by` start), `finish!` (`finished_at`, `exit_status`).
- `lib/soft_foundry/cli.rb`: the `phase run` command (options, `--` pass-through, refusal, guard warning, dry run, billing notice, spawn with inherited stdio, gate and advisories on return, exit codes); a `runner:` injection point for tests; help text.
- `lib/soft_foundry/shell.rb`: `Shell.resolve` split out of `launch` so the runner can spawn without `exec`.
- `lib/soft_foundry/advisory.rb`: `fresh_context_notices` for a completed review or judgment without `executed_by.fresh_context`.
- `lib/soft_foundry/gate.rb` `staleness_check` and `lib/soft_foundry/git.rb` (`changed_between`, `branch_tip`): staleness measured on the record's own branch when it exists and is not checked out.
- `lib/soft_foundry/hooks.rb`: both hook commands prefer a checkout's `exe/soft-foundry` over a gem on PATH.
- `.ai/templates/handoff.yml`: `executed_by: null` with its comment. `.ai/schemas.md`: the field and the staleness rule. `.ai/repository.yml`: `governance.separation_of_duties: PASS`. `.ai/maturity.yml`: its assessment rule. `README.md`: "Fresh-context phases: `phase run`" and the staleness sentence. `AGENTS.md` step 9: never write `executed_by`.
- `.claude/settings.json` (new, committed): the guard hook for this repository (runtime-guard REV-025).
- Tests: `test/phase_runner_test.rb` (8: refusals, dry run and prompt, guard warning present and absent, a run with a fake shell that completes the phase, a failed session, a failing gate, the advisory, the template field), `test/stacked_branch_test.rb` (5: stacked branch not stale, own branch measured by worktree, a commit on the record branch seen from the stack, deleted branch falls back to HEAD, `ci` passes on a stack), three `AdvisoryTest` cases now mark their review runner-executed.
- Version bumped to 0.11.0.

## Decisions
See `decisions.md`.

## Deviations from plan
Two additions the plan did not contain, both forced by this change's own process; see `deviations.md`.

## Lessons
- The tool caught its own process twice. `ci` on this stacked branch correctly reported runtime-guard's evidence as stale against code it never saw, which exposed that "stale" had been defined against the worktree rather than the record's branch. And the pre-commit hook silently ran an installed 0.3.0 and rejected two commits whose evidence had already been generated, so that evidence was thrown away and regenerated at the real commit rather than kept.
- A runner that refuses what the gate would refuse spends no session on a phase that cannot complete. The four refusals are the gate's own rules read before launch.
- `executed_by` is the cheapest possible proof of a process boundary: a field the agent is told not to write and the advisory reads. It is not tamper-proof (an agent could write it), which is the same trust level as `vetted` and `human_decisions`, and the review says so.

## Challenges
- Two implementation commits were rejected by the pre-commit hook and the failure was not noticed until the printed "implementation commit" hash matched the scaffold's. Evidence generated in between was deleted and regenerated at commit 9f855b5. Root cause and fix in `decisions.md`.
