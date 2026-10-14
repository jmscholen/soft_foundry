# Final Judgment

## Outcome
**APPROVED_WITH_RESIDUAL_RISK**

## Commit judged
`625e0da60e7c33ded16566366a68e661e764522f` (branch `change/panel-phases`, HEAD when this judgment was written).

The panel code is `4f3b2da` (REM-003). `4f3b2da` is an ancestor of `625e0da`. `git diff 4f3b2da..625e0da -- lib exe test spec infra` is empty, and the worktree has no uncommitted change under those paths. Commits after `4f3b2da` record verification, the live evaluation, the attack pass, the fourth review, and the maintainer's residual-risk decision. This judgment also read `Panel#repository_snapshot`, `#identical_drafts`, and `#staging_for`, `CLI#spawn_panel` and the handoff merge in `panel_run`, and `Guard.mode` / `narrow_for_panel`. It did not re-run the review's throwaway attacks and it did not edit application code.

## Requirements status
REQ-PN-001, REQ-PN-004, REQ-PN-005 on a clean split, REQ-PN-006, REQ-PN-008, REQ-PN-009, and REQ-PN-010 hold. Verification maps each to a test. The fourth review re-read the code. Version is `0.20.0`. Help text in `lib/soft_foundry/cli.rb` names `--panel`. `.ai/schemas.md` describes the `panel:` block and the `panel recorded` check. `.ai/policies/human-boundaries.yml` lists a panel split. The README panel section matches the runner for an honest panel.

REQ-PN-002 does not fully hold. A member that lists `soft-foundry-panel-*` in the system temp directory, copies the other draft, and adds one byte still finishes as agreed (REV-SEC-011). The README already says the runner catches a copy only when the drafts are identical.

REQ-PN-003 holds for where agreement is read: only the bytes that member appended on its own turn. It does not hold for "one sentence". Both members can append the same paragraph and the panel agrees (REV-FUN-007, also seen live as EVAL-OBS-001).

REQ-PN-007 holds for the guard's known tools. In the argument stage, shell narrowing flags only paths inside the phase directory. The snapshot is the control for every other write, and that control does not see `.git/hooks`, gitignored files, or a write that lands after `Process.wait` returns (REV-SEC-012, REV-SEC-013, REV-SEC-014).

The specification phase was skipped. There is no separate acceptance-criteria file in force. The intake IDs above are the requirements. No criterion is left waiting on a real-world event. `undischarged` is empty.

## Verification
**Disposition: passed, current for the judged code.** Bound to `4f3b2dadb445605f059bc1ff942d0de183d35044`, the fourth run, after REM-003. CHECK-001: 515 runs, 3,419 assertions, 0 failures, 0 errors. RED commits `553030c`, `2ca6ff2`, `f638ea4`, `f69d6f2`, and `d7dca1a` fail as intended, and code changed after each. `soft-foundry check`, `ruby -wc`, and `soft-foundry scan` passed. `test_shell_args_reach_only_their_shell` shares GREEN commit `d1cf0d6` and has no RED commit of its own (REV-FUN-002, implementation deviation 2). `soft-foundry change status` reports this phase ok.

## Evaluation
**Disposition: passed, current.** Bound to `4f3b2da`. EVAL-001 through EVAL-004 passed on a live Claude Code and Grok panel in a scratch repository: two argument rounds, drafts that differed, both draft folders cited, `panel recorded` passed, `failures` and `dropped` empty. A split, a Codex member, and a four-member panel were not run live. Codex is a stated non-goal. EVAL-OBS-001 is the paragraph-length `agree:` line. EVAL-OBS-002 is the pre-existing guard warning on shell reads of deny-write paths.

## Attack
**Disposition: no violations on the cases it ran; those cases do not cover the fourth review's new majors.** Bound to `4f3b2da`. ATTACK-002 through ATTACK-008 were denied, including the synchronous repository writes REM-003 added. ATTACK-001 was not run against a live model. The attack record already says a paraphrased temp-directory copy is not caught, and that a malformed `SOFT_FOUNDRY_PANEL_MEMBER` skips narrowing (ATK-RES-001). It does not mention a detached child, a `.git` hook, a gitignored guard override, or a retry over a planted file. The fourth review ran those. This pass was the session that implemented the change, not a separate attacker. Review then reproduced the closed cases and found the new ones. That limit is recorded below. It is not a reason to discard the transcript.

## Documentation
`10-user-documentation` and `11-faq-index` are pending. Both are optional, and this change did not start them. REQ-PN-010 puts the user-facing text in the README, the help text, `.ai/schemas.md`, and the human-boundaries entry. Those exist and review checked them. The unstarted phases are accounted for.

The README sentence "Anything else fails the run" is broader than the code. The comparison is `git ls-files -co --exclude-standard`, taken when the direct child exits. REV-SEC-012, REV-SEC-013, REV-SEC-014, and the retry in REV-SEC-015 do not fail. The next paragraph does say members are not sandboxed and that only an identical temp-directory copy is caught. The overclaim is residual risk, not a missing documentation phase.

## Observability
`12-observability` is pending and optional. `surfaces.observability` is false. There is no deployed service, metric, or alarm to add. The operator signal is the `panel:` / `fail panel:` / `warn panel:` line, the exit code, and the handoff. That signal is right for a synchronous git-visible write: review reproduced exit 1 and a `fail panel:` line that names the file. It is a false pass for REV-SEC-012, REV-SEC-013, and REV-SEC-014, and a false pass on the second run in REV-SEC-015. That is residual risk in the detector the remediation documented. It is not a missing production dashboard.

## Review findings
`13-review` is complete at `661b454458508391ba341fea32c5bcb6668d20e8`. No application, test, or infrastructure file changed between that commit and `625e0da`. **No blocking findings.** The review ran on xAI. Implementation and remediation ran on Anthropic.

Closed and reproduced in this review, not reopened: REV-SEC-007 (handoff), REV-SEC-008 for a synchronous git-visible `lib/app.rb`, REV-SEC-009 for byte-identical drafts, REV-SEC-010 (dotfile), REV-FUN-006 (a failed split is not parked). Earlier remediations closed REV-SEC-001..006, REV-FUN-001, and the folded minors.

Open, and the reason this is not a clean approval:

- REV-SEC-011 (major). Staging directories are `Dir.mktmpdir("soft-foundry-panel-")`. Listing the system temp directory finds them. The comment on `staging_for` says a member cannot find the other by listing a shared parent. `#identical_drafts` compares raw bytes, so one added newline is not identical and the panel completes as agreed. Confirmed in the code. The README already states this limit.
- REV-SEC-012 (major). `spawn_panel` is `Process.spawn` plus `Process.wait` on that pid. A double-fork with `Process.setsid` is still running when the snapshot is taken. A later write of a tracked file is a success with `outcome: agreed`. Confirmed: the method does not use a process group.
- REV-SEC-013 (major). `repository_snapshot` is `git ls-files -co --exclude-standard`. That listing never includes `.git/hooks`. An argument-stage shell write of an executable `pre-commit` is outside the phase directory, so `narrow_for_panel` does not flag it either. The next `git commit` runs the hook. Confirmed in both methods.
- REV-SEC-014 (major). The same listing skips gitignored files. `.soft-foundry/enforcement.yml` is gitignored. `Guard.mode` returns `off` when `guard.mode` is the string `off`. A YAML boolean `off` becomes `"false"` and does not match. A member that writes the quoted form turns the guard off for later sessions on that checkout, and the panel exits 0. Confirmed in `Guard.mode`.
- REV-SEC-015 (major). A detected write is not restored. `panel_run` sets the handoff to `blocked` and does not refuse a later run. The next snapshot's baseline is the worktree, so the planted file is no longer a change. The first run does exit 1 and names the file.
- REV-SEC-016 (minor). On that failure path the runner loads the handoff and overlays `status`, `blocking`, `panel`, and `executed_by`. A planted `findings` list is kept. Confirmed in `panel_run`.
- REV-FUN-007 (minor). `agree:` is not held to one sentence.
- REV-FUN-008 (minor). Deleting `ARGUMENT.md` raises `Errno::ENOENT`. The CLI prints a path error with no `fail` word, and the handoff stays pending.
- REV-FUN-009 (minor). A consensus-stage stray write blocks the run but leaves `panel.outcome` as `agreed` or `split`.
- REV-FUN-002 (minor). `--shell-arg` has no RED commit of its own.
- REV-ARCH-001 (minor). `Gate.checks_for` lists `panel recorded` for every panel phase. `evaluate` runs it only when a complete handoff has a `panel:` block. REQ-PN-006 requires the check when the block is present.
- REV-ARCH-002 (minor). Control-plane and README writes sit outside the implementation write set. Accepted because REQ-PN-001, REQ-PN-005, and REQ-PN-010 require them and no skill can write them.

Functional and security do not conform, because of REV-SEC-011..015. Operations does not conform for that same detector. Architecture conforms with the two minors. Accessibility conforms with the REV-FUN-008 advisory. Policy conformance is N/A: `surfaces.policy` is false, and no published privacy, security, or terms document exists to change. Infrastructure is N/A.

`metadata.yml` `human_decisions` records the maintainer's acceptance of REV-SEC-011..015, and says the cheap fixes (rerun refusal, the `ARGUMENT.md` crash, `outcome: failed` on a consensus stray write) go to a follow-up. That entry is who accepted the risk. It does not make REQ-PN-002 met.

The skipped specification leaves the go-live accessibility advisory that no `category: accessibility` requirement was recorded. That advisory is not a failed requirement of this change.

## Residual risk
See `residual-risk.md`. The items accepted by merging are the unsandboxed same-user holes REV-SEC-011..015, the false comfort of the README sentence "Anything else fails the run", and the smaller functional, accessibility, architecture, and attack residuals below.

## Reasoning
Every required phase is complete and its gate is ok (`soft-foundry change status`). Discover, specify, and plan are pending because `skipped_phases` records a rationale for each. Documentation, the FAQ index, and observability are pending and optional, and they do not leave a specified requirement unmet. Verification, evaluation, and attack describe `4f3b2da`, which is the application code at the judged commit. Review describes that same code. Implementation's own commit, `d1cf0d6`, is not the current code. REM-001, REM-002, and REM-003 changed it, and the later phases re-ran against `4f3b2da`.

`BLOCKED` would be the outcome if a locked requirement failed for a panel whose members stay inside the prompts, if a specified mitigation the change still claims as closed were unmet on the inputs it names, or if review had returned blocking findings. Review returned none. The synchronous git-visible writes REM-003 names are caught: review reproduced them, and the code compares that listing when the direct child exits. The live panel agreed with two different drafts. The open majors are a same-user agent that already runs as the person who launched it. REV-SEC-011 is the limit REM-003 and the README asked judgment to accept. REV-SEC-012 is that same limit after the waited-for process has exited: closing every later write needs an OS sandbox, which this change does not set up. REV-SEC-013 and REV-SEC-014 are real blind spots of the listing the remediation chose, and they are invisible to `git status`. They are accepted here, not sent back, because the attacker is that same user, the honest-panel path holds, and another remediation loop would be chasing writes the user's agent can also perform outside a panel. They are not marked closed. REV-SEC-015's first run fails and names the file. The maintainer already sent the rerun refusal to a follow-up. Returning the change to remediation would treat that recorded decision as if it had not been made.

`REJECTED` does not fit. The intake is sound, the implementation matches it for the panel a person runs in good faith, and the attack cases that were in scope were denied.

`APPROVED` does not fit either. Five majors are open. Security, functional review, and the operator signal do not conform for those inputs. A maintainer should merge knowing that, which is **APPROVED_WITH_RESIDUAL_RISK**.
