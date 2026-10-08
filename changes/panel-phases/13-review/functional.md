# Functional Review

Reviewed at commit `726edc107151e91e708ea8ba4ce367ee516bf19f` (panel behavior is `d1cf0d6`; `726edc1` records the earlier phases). Requirements are REQ-PN-001..010 in `00-intake/request.md`. Compared with `lib/soft_foundry/panel.rb`, `lib/soft_foundry/cli.rb` (`panel_run`, `spawn_panel`), the panel tests, and the live panel in `07-evaluation/evidence/live-panel-transcript.log`.

## Scope reviewed

The panel command: member naming and bounds, refusals (implement, `--panel` with `--shell`, round limits, one member), `--shell-arg`, dry run, independent and argument stages, agreement from each member's own appended text, a spoiled round, consensus, the `panel:` handoff block, split parking, the single-provider advisory, and help text. Reproduced the failure-path claims below in a throwaway repository with the real `CLI` and `Guard` classes and a stand-in launcher. Did not launch a live coding shell.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-001 | major | `Panel#run`; `CLI#panel_run`; `CLI#spawn_panel` | The runner never looks at a member process's result. `Panel#run` discards the launcher's exit statuses. `panel_run` always writes `executed_by.exit_status: 0` and does not call `PhaseRunner#begin!`, so a panel that dies mid-run is not an unfinished recorded run (`Processes#recorded_runs` needs `executed_by.finished_at` nil). A consensus process that exits non-zero before it edits the handoff leaves `status: pending`; the gate skips every check and the command exits 0. Members that exit non-zero without writing an `agree:` line are recorded as a split: the change is parked at `awaiting_human` and the blocking line says a person must decide between positions. `spawn_panel` resolves and spawns inside one `map` with no `ensure`: if a later member's executable is missing, `Shell.resolve` raises, `CLI#run` prints the error and returns 1, and any member already spawned is not waited on or killed. | `phase run specify --panel claude,grok --max-rounds 1`, both members append `agree: same`, consensus launcher returns 1 and does not touch the handoff. Reproduced: command exits 0, handoff `status` is `pending`, `executed_by.exit_status` is 0, `panel.outcome` is `agreed`, gate prints `02-specification pending SKIP` / `phase pending: not started`. Same launcher returning 1 from every stage with no writes: command exits 1, `status` is `awaiting_human`, handoff is `blocked`, `outcome` is `split`, `exit_status` is 0, blocking says the panel did not agree. `--panel grok,claude` when `claude` is not on PATH (code path, not launched): grok is spawned, then resolve raises, and that process is left running. | `.ai/rules/errors.md` (failures surfaced, a fallback must not turn a failure into something else); `.ai/rules/general.md` (do not swallow errors); `.ai/rules/observability.md` (a new failure mode needs a detection path); REQ-PN-004, REQ-PN-005 |
| REV-FUN-002 | minor | `test/panel_phases_test.rb` `test_shell_args_reach_only_their_shell`; `05-implementation/deviations.md` item 2 | `--shell-arg` is the right extension: a mixed panel cannot share one `--` argument list for Claude Code's `--permission-mode` and Grok's `--always-approve`, and the arguments stay argv elements to `Process.spawn`, not a shell string. The test was written in the same commit as the code (`d1cf0d6`), so this behavior has no RED commit of its own. The feature is accepted. The process miss is not. | A regression in which shell receives which flag would not have a commit where that test already failed. The test does exist and passes at HEAD, so this is the evidence gap, not an untested behavior. | `.ai/rules/testing.md`; `.ai/rules/learned.md` (`commit-the-failing-test-first`) |
| REV-FUN-003 | minor | `CLI#panel_run` dry-run branch | `--dry-run` prints members, providers, the round limit, the session cap, and the independent-round commands only. Session ids already exist, so the later `--resume` commands and the consensus command could be printed and are not. Evaluation treated the independent commands as "each launch command" (EVAL-001) and that reading matches the test. | `phase run review --panel claude,grok --dry-run` never shows the argument-round `--resume` command or the consensus command. The operator sees the session cap but not those launches. Nothing is started, which is the part that must not fail. | REQ-PN-009 |

## Deviations

1. Writes to `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, and `README.md` are outside the implementation write set. Accepted. REQ-PN-001, REQ-PN-005, and REQ-PN-010 require those files, and no skill's write set covers them. The maintainer still accepts the control-plane edit at merge.
2. `--shell-arg` is accepted. See REV-FUN-002 for the missing RED commit.
3. The regex escape corrected in `d1cf0d6` before the commit, with no behavior change, is accepted. No finding.

## What holds

REQ-PN-001 refusals and bounds, member names `<shell>-<n>`, Claude Code and Grok resume versus a fresh Codex session, agreement taken only from text appended on that member's turn, a forged `agree:` line, a rewritten `ARGUMENT.md` spoiling the round, the `panel:` block, split setting `blocked` and `awaiting_human` when members actually disagree, the single-provider advisory, and version 0.20.0 all match the intake and the tests. The live panel (claude-1, grok-1, one round, gate `panel recorded` pass) is consistent with that code. Help text matches the command.

## Conformance

Conforms on the paths the tests and the live panel exercised. Does not conform on member-process failure (REV-FUN-001).
