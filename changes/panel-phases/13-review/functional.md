# Functional Review

Reviewed at commit `11c69d2045fe1d1db2e3118b7e3f17f401b95169`. Panel behavior is `2a74680`. Requirements are REQ-PN-001..010 in `00-intake/request.md`. Compared with `lib/soft_foundry/panel.rb`, `lib/soft_foundry/cli.rb` (`panel_run`, `spawn_panel`), `lib/soft_foundry/guard.rb`, `test/panel_phases_test.rb`, `test/panel_remediation_test.rb`, and the live panel in `07-evaluation/evidence/live-panel-transcript.log`.

`ruby -Ilib:test test/panel_remediation_test.rb` passed here: 29 runs, 185 assertions, 0 failures. That file loads the original panel tests as well. The first review's REV-FUN-001 and REV-FUN-003, and the second review's REV-FUN-004 and REV-FUN-005, are closed on the inputs they named.

## Scope reviewed

Member naming and bounds, refusals, `--shell-arg`, dry run, independent and argument stages, agreement from text appended on that member's turn, a spoiled round, consensus exit status, the `panel:` block, split parking, a panel that loses a member, drafts written only in the repository, and help text. Reproduced the cases below with the real `CLI`, `Panel`, and `Guard` classes and a stand-in launcher in a throwaway repository. Did not launch a live coding shell.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-006 | minor | `CLI#panel_run` split handling | A consensus-stage integrity failure still uses outcome `split` or `agreed`, not `failed`. The split branch then parks the change. The README says a failed panel is blocked and is not parked, because there is nothing to decide. Early failures (independent or argument) do return outcome `failed` and do not park. | `--panel claude,grok --max-rounds 1`, neither member writes `agree:`, and the consensus replaces `panel/grok-1/draft.md`. Reproduced: exit 1, `panel.outcome` is `split`, `panel.failures` names the replaced draft, stderr has both `✗ fail panel:` and `! warn panel: split ... parked`, handoff `blocking` has `panel split:` and `panel failed:`, and metadata `status` is `awaiting_human`. The cited draft is the replacement. | REQ-PN-005; README "Panels" (a failed panel is not parked); `.ai/rules/errors.md` |
| REV-FUN-002 | minor | `test/panel_phases_test.rb` `test_shell_args_reach_only_their_shell`; `05-implementation/deviations.md` item 2 | `--shell-arg` is the right extension: a mixed panel cannot share one `--` list, and the values are argv elements to `Process.spawn`. The test was written in the same commit as the code (`d1cf0d6`). Remediation did not give it a RED commit of its own. The feature is accepted. | A regression in which shell receives which flag would not have a commit where that test already failed. The test passes at HEAD. | `.ai/rules/testing.md`; `.ai/rules/learned.md` (`commit-the-failing-test-first`) |

Integrity failures that make a completed phase cite the wrong bytes, or record one member's draft twice, are REV-SEC-007, REV-SEC-008, and REV-SEC-009 in `security.md`. Each one exits 0 with `outcome: agreed` and an empty `panel.failures`.

## Deviations

1. Writes to `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, and `README.md` are outside the implementation write set. Accepted. REQ-PN-001, REQ-PN-005, and REQ-PN-010 require those files, and no skill's write set covers them. The maintainer still accepts the control-plane edit at merge.
2. `--shell-arg` is accepted. See REV-FUN-002 for the missing RED commit.
3. The regex escapes corrected before `d1cf0d6` and again in `2bdc19f`, with no behavior change, are accepted.

## What holds

REQ-PN-001 refusals and bounds, member names `<shell>-<n>`, Claude Code and Grok resume versus a fresh Codex session, Claude's `--add-dir` for the staging folder, agreement taken only from text appended on that member's turn, a forged `agree:` line, a rewritten `ARGUMENT.md` spoiling that round, a non-zero consensus failing the command and recording `executed_by.exit_status`, fewer than two staged drafts failing instead of splitting, shells resolved before any member starts, the `panel:` block, `dropped` when a member writes nothing, split setting `blocked` and `awaiting_human` when the drafts are intact, the single-provider advisory, dry-run lines for the independent, first argument, and consensus commands, and version 0.20.0 all match the intake and the tests.

A missing executable no longer starts an earlier member. A `Process.spawn` error after both executables have resolved is still not waited or killed; that input was not reached, and it is not a finding.

The live panel (claude-1, grok-1, one round, gate `panel recorded` pass, exit 0) matches this code. Its agree line is one long sentence copied by both members, which is what the equality check specifies; nothing rejects a sentence that is longer than the prompt asks for (EVAL-OBS-001). Help text matches the command.

Controls re-run here, all failing closed: an independent write of `specification.md` exits 1 with outcome `failed` and no consensus; an argument-stage replacement of the other draft exits 1 with outcome `failed` and no consensus; an in-repository `Write` of `panel/<member>/draft.md` is a guard violation.

## Conformance

Does not conform. The paths the tests and the live panel exercise hold, including the functional majors from the first review. An agreed panel can still complete after a planted handoff, a replaced file outside the phase folder, or a draft copied from the other member (REV-SEC-007, REV-SEC-008, REV-SEC-009). REV-FUN-006 parks a tampered split.
