# Functional Review

Reviewed at commit `a47a2f35ba68fd3cce6b3e703348e65debaf8ffb` (panel behavior is `2bdc19f`, an ancestor; `a47a2f3` records the remediation rerun). Requirements are REQ-PN-001..010 in `00-intake/request.md`. Compared with `lib/soft_foundry/panel.rb`, `lib/soft_foundry/cli.rb` (`panel_run`, `spawn_panel`), `lib/soft_foundry/guard.rb`, `test/panel_phases_test.rb`, `test/panel_remediation_test.rb`, and the live panel in `07-evaluation/evidence/live-panel-transcript.log`.

The first review's REV-FUN-001 (member exits discarded, a non-zero consensus exiting 0, a missing executable started after another member) and REV-FUN-003 (dry run omitted the argument and consensus commands) are closed. `test/panel_remediation_test.rb` and `test/panel_phases_test.rb` passed together here: 24 runs, 167 assertions, 0 failures.

## Scope reviewed

Member naming and bounds, refusals, `--shell-arg`, dry run, independent and argument stages, agreement from text appended on that member's turn, a spoiled round, consensus exit status, the `panel:` block, split parking, a panel that loses a member, drafts written only in the repository, and help text. Reproduced the new cases below in a throwaway repository with the real `CLI`, `Panel`, and `Guard` classes and a stand-in launcher. Did not launch a live coding shell.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-004 | minor | `Panel#run` dropping members before the argument | With three or four members, a member who writes no staged draft is removed and the rest may agree. `panel.members` then lists only whoever remains. The warning and `panel.notes` name the dropped member. A two-member panel still fails closed, which is what the remediation test covers. | `phase run specify --panel claude,grok,codex --max-rounds 1`, codex-1 exits 1 with no draft, claude-1 and grok-1 append `agree: same`. Reproduced: command exits 0, `panel.outcome` is `agreed`, `panel.members` is only claude-1 and grok-1, handoff status is `complete`. Stderr is `! warn panel: continuing with claude-1 and grok-1; codex-1 exited 1 with no draft`. | REQ-PN-003 (every member's section agrees); `.ai/rules/errors.md` (a fallback must not turn a failure into success). The README states the fewer-than-two threshold, so this is the disclosed remainder, not a silent one. |
| REV-FUN-005 | minor | `Panel#collect_drafts` | The runner counts a draft only in `SOFT_FOUNDRY_PANEL_DRAFT_DIR`. A file written at `<phase>/panel/<member>/`, which REQ-PN-007 and the guard still allow, is not a draft. The prompt tells the member to use the staging folder, and the live panel did. | `phase run specify --panel claude,grok`, both members exit 0 after writing only `panel/<member>/draft.md`. Reproduced: command exits 1, outcome `failed`, status `blocked`, notes say each member exited 0 with no draft, and both `draft.md` files are left in the phase folder. | REQ-PN-002, REQ-PN-007 |
| REV-FUN-002 | minor | `test/panel_phases_test.rb` `test_shell_args_reach_only_their_shell`; `05-implementation/deviations.md` item 2 | `--shell-arg` is the right extension: a mixed panel cannot share one `--` list, and the values are argv elements to `Process.spawn`. The test was written in the same commit as the code (`d1cf0d6`). Remediation did not give it a RED commit of its own. The feature is accepted. | A regression in which shell receives which flag would not have a commit where that test already failed. The test passes at HEAD. | `.ai/rules/testing.md`; `.ai/rules/learned.md` (`commit-the-failing-test-first`) |

Integrity failures that make a completed phase cite the wrong bytes are REV-SEC-004, REV-SEC-005, and REV-SEC-006 in `security.md`. They are functional as well as security: each one ends with exit 0 and `outcome: agreed`.

## Deviations

1. Writes to `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, and `README.md` are outside the implementation write set. Accepted. REQ-PN-001, REQ-PN-005, and REQ-PN-010 require those files, and no skill's write set covers them. The maintainer still accepts the control-plane edit at merge.
2. `--shell-arg` is accepted. See REV-FUN-002 for the missing RED commit.
3. The regex escapes corrected before `d1cf0d6` and again in `2bdc19f`, with no behavior change, are accepted.

## What holds

REQ-PN-001 refusals and bounds, member names `<shell>-<n>`, Claude Code and Grok resume versus a fresh Codex session, Claude's `--add-dir` for the staging folder, agreement taken only from text appended on that member's turn, a forged `agree:` line, a rewritten `ARGUMENT.md` spoiling that round, a non-zero consensus failing the command and recording `executed_by.exit_status`, fewer than two staged drafts failing instead of splitting, shells resolved before any member starts, the `panel:` block, split setting `blocked` and `awaiting_human`, the single-provider advisory, dry-run lines for the independent, first argument, and consensus commands, and version 0.20.0 all match the intake and the tests. The live panel (claude-1, grok-1, one round, gate `panel recorded` pass) is consistent with that code. Help text matches the command.

A missing executable no longer starts an earlier member. A `Process.spawn` error after both executables have resolved is still not waited or killed; that input was not reached, and it is not a finding.

## Conformance

Conforms on the paths the tests and the live panel exercised, including the four majors from the first review. Does not conform on a three-or-four-member panel that drops a silent member (REV-FUN-004) or on the integrity cases in the security review.
