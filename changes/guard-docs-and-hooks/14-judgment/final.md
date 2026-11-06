# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
`91b170067ebf07eb00e77432d9dc8638bc9d90f5` (HEAD of `change/guard-docs-and-hooks`, the seal of 13-review). The working tree differs from it only in this phase's `handoff.yml`, which the runner opened.

The diff from `main` outside `changes/` is six files in two commits. The maintainer commit `b9f4d7c` changed `.ai/harness-evals/README.md` (6 lines added), `.ai/policies/enforcement.yml` (header comment only; `guard.mode: block` unchanged), and `.claude/settings.json` (the current hook install). The documentation commit `5b2a028` changed `README.md`, `docs/user/README.md`, and `docs/user/guard-hook.md` (new). `.codex/hooks.json` was rewritten byte-identical by the reinstall and does not appear in the diff. No file under `lib/`, `test/`, `exe/`, `.github/`, or `infra/`, nor the `Rakefile`, `Gemfile`, or gemspec, differs from `main` or changed after the verification commit `6af7142`, the evaluation commit `2af76ba`, or the review commit `5b2a028`. Every commit-bound phase is therefore current for this commit, and the gate on each reports the same.

## Requirements status
The requirements are REQ-GDH-001 to REQ-GDH-005 in `00-intake/request.md`. The specify phase is waived at low risk; `02-specification/` holds the unfilled scaffold, whose AC-001 this judgment sets aside in `evidence.yml`.

| ID | Result |
| --- | --- |
| REQ-GDH-001 | Met. Both hook files equal a fresh `hooks install` (CHECK-006, EVAL-002); the PreToolUse matcher is `Edit\|Write\|MultiEdit\|NotebookEdit\|Read\|Grep\|Glob\|Bash` and a PostToolUse entry with matcher `Bash` runs `guard --after`. The committed hook refused Grep and Glob into `.ai/harness-evals` and shell commands naming its own configuration in the verification, evaluation, review, and this session (CHECK-007, EVAL-001; this session's refusal is in the handoff notes). Rerunning the install on a pre-0.21.0 file upgrades it and is idempotent (EVAL-003, 13 of 13). `doctor`'s guard line passes. |
| REQ-GDH-002 | Met with two inaccuracies carried as a condition. Every claim in the header a command can check holds (CHECK-009; EVAL-004, 84 of 86 with the 2 explained as wrong expectations in the script; review functional.md traced each to code). Two statements do not hold as written: `off` is listed among the file's values without saying it must be quoted, since a bare `off` is YAML's boolean false and the file is then ignored (EVAL-005 fail, EVAL-F-001); and "outside a change branch nothing is guarded" omits that the post-call restore runs on every branch and that the pre-call guard disengages at status `judged` (REV-GDH-002). The header is protected policy and a maintainer edit; carried as GDH-3. |
| REQ-GDH-003 | Not checked by the lifecycle. `.ai/harness-evals/**` is in the deny_read set of verification, evaluation, documentation, review, and this skill (VER-002, EVAL-F-004, REV-GDH-007). `git` shows the file gained six lines in `b9f4d7c`; nobody in the lifecycle has read them. The maintainer reads the file at merge; carried as GDH-1. |
| REQ-GDH-004 | Met in coverage, with one instruction that the tool undoes. Every item intake lists is in the README guard section and harness-evals section, and in `docs/user/guard-hook.md`, each claim traced to code by review (functional.md). The "Mode" paragraph and the user page's "Change the mode on your machine" tell a maintainer to turn the guard off on their machine with `mode: "off"` in `.soft-foundry/enforcement.yml`; with that override in place the pre-call hook returns before recording a baseline and the post-call hook reads the missing baseline as "committed policy, no override", deletes the override, reports a tamper, and leaves the mode at `block` (REV-GDH-001, major, probed in `13-review/evidence/off-override-probe.txt` cases A to C; confirmed by this session against `cli.rb` `guard`, which returns at `mode == "off"` before `record_baseline!`, and `guard_after`, which calls `check_after!` unconditionally). The text correction, or the code fix that makes the text true, is carried as GDH-2. |
| REQ-GDH-005 | Met. Only the six files above differ from `main` (CHECK-008, EVAL-008); the full suite passed on tree `82a4bbdc` (902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips; CHECK-001), `check`, `eval` (28 passed, 1 live case skipped) and `ci` pass (CHECK-002 to 004, EVAL-008), and the code tree is unchanged since. |

## Verification
Complete and current. Handoff commit `6af7142`, fresh session (anthropic, claude-fable-5-1). Nine checks: eight pass, CHECK-005 (`doctor`) fails on three machine-local lines of a fresh checkout (no `.ai/manifest.yml`, no pre-commit hook, no `.soft-foundry/runtime.yml`) that predate the change, while the guard-hook line REQ-GDH-001 bears on passes (VER-001). No check names an acceptance criterion because none exists; each names its requirement. The gate passes, with the AC-001 warning this judgment closes.

## Evaluation
Complete and current. Handoff commit `2af76ba`, fresh session (anthropic, claude-fable-5-1), size `full_route_sweep`.

| Journey | Result | What it establishes |
| --- | --- | --- |
| EVAL-001 | pass | The committed hook refused six of the session's own calls, Grep and Glob among them |
| EVAL-002 | pass | `doctor` guard line; both hook files equal a fresh install |
| EVAL-003 | pass | Rerun of `hooks install --claude` on an old file: matcher replaced, PostToolUse added, unrelated entries kept, idempotent |
| EVAL-004 | pass | 84 of 86 header claims fed to the guard as payloads hold; the 2 are wrong expectations in the script |
| EVAL-005 | fail | `mode: off` unquoted in a file is read as false and ignored (EVAL-F-001) |
| EVAL-006 | blocked | REQ-GDH-003 denied to the skill |
| EVAL-007 | blocked | README not yet written at that commit; the absent items are recorded for review, which found them all present at `5b2a028` |
| EVAL-008 | pass | 57 of 62 routes as expected; the 5 explained (sandbox proxy, correct refusals); `check`, `eval`, `ci` pass |
| EVAL-009 | pass | CLI output meets the accessibility rules |

EVAL-F-002 is a code defect met on the way: a `cd` or `pushd` out of the repository followed by another token in the same segment raises in `shell_paths` and the command is refused as undecidable. It fails closed and is documented as current behaviour; it is for a later record (REQ-GDH-005 forbids code here).

## Attack
Waived at low risk with a rationale in `metadata.yml`: no code change; the guard behaviour the text describes was attacked in five rounds in `changes/factory-readiness` and `changes/gate-hardening`. Security review conforms: block mode unchanged, no control weakened, the published list of limits is the accepted residual of factory-readiness, and REV-GDH-001 fails toward the stricter mode. This judgment relies on that review and the waiver.

## Documentation
Complete. Handoff commit `1f3a059` (sealed `972125d`; the README and `docs/user/` files it wrote were committed as `5b2a028`, which review examined). Fresh session (anthropic, claude-fable-5-1), rerun once after a manual reopen because the first run's handoff notes quoted the gate's placeholder marker; the outputs did not change. The README guard section, the harness-evals paragraph with the live-eval invocation, the user page, and its index carry every item of REQ-GDH-004 (DOC-F-001). EVAL-F-001 (quote `off`), EVAL-F-002 (the undecidable `cd` with a redirection) and EVAL-F-006 (an Edit validated by the host before the hook) are in the text. Four claims rest on factory-readiness evidence rather than a journey here (DOC-F-002): the live-eval invocation, the thirty-minute baseline age, the list of what gets past the restore, and the Grok sentences; review traced the first three to code or to the earlier record and found the Grok post-call claim unevidenced (REV-GDH-004).

`11-faq-index` is optional and pending, unwaived. Its input exists: twelve records FAQ-GDH-001 to 012 in `10-user-documentation/search-records.yml` (DOC-F-006). Nothing in the deliverable depends on the index; the phase may be run later. FAQ-GDH-002 repeats the off-mode instruction GDH-2 corrects, so whoever runs the index does so after that correction. Its handoff is in the judged commit.

## Observability
`12-observability` is optional and pending, unwaived. `surfaces.observability` is false, the change ships no service and no code, and the guard log, the operational signal, is unchanged. No metric, alarm, dashboard, or runbook is owed. Its handoff is in the judged commit.

## Review findings
Complete and current. Handoff commit `5b2a028`, sealed as `91b1700`, fresh session stamped by the runner (anthropic, claude-fable-5-1). The runner started it on the same provider as implementation; the gate advises on that, and the choice was the runner's. No blocking finding. All seven review files conform, with the following findings.

- **REV-GDH-001, major.** The documented file override `mode: "off"` is deleted by the first shell command's post-call check, which then reports a tamper and leaves the mode at `block`; `SOFT_FOUNDRY_GUARD=off` likewise removes an override file or reverts an uncommitted policy edit. Root cause is code (`cli.rb` `guard` skips the baseline in off mode, `guard_after` does not skip the check) and out of this change's scope. Accepted as residual risk with the correction as condition GDH-2: it fails toward the stricter mode, exposes nothing, the variable route is documented beside the file route and works when no override file and no uncommitted policy edit exist, and `mode: "warn"` in the file works (probe case D). Not BLOCKED, because that transition returns to remediation, whose write set is application, test, and infrastructure code and denies `docs/`, and `README.md` is in no group it may write; remediation could neither make the code fix REQ-GDH-005 forbids nor correct the text. The correction belongs to a person at merge, a reopened documentation phase, or a later record.
- **REV-GDH-002, minor.** Scope wording: the post-call restore runs on every branch, and the pre-call guard disengages at `judged`, not `closed`, so the learn phase runs unguarded. Wording folded into GDH-2 and GDH-3; the code decision is for a later record.
- **REV-GDH-003, minor.** The log gets a `tamper restored=` line with nothing restored when the baseline is missing. Wording or code, for a later record; accepted.
- **REV-GDH-004, minor.** The Grok post-call claim is unevidenced. Accepted; hedge it when the text is next revised (GDH-2).
- **REV-GDH-005, minor.** The protected header's two inaccuracies. Condition GDH-3.
- **REV-GDH-006, minor, accessibility advisory.** The README section's six sub-topics are bold lead-ins, not headings (WCAG 2.2 1.3.1, 2.4.6); the user page has the same content under real headings. Accepted as a go-live advisory.
- **REV-GDH-007 to 010, informational.** REQ-GDH-003 unread (GDH-1); a gate test writes the override unquoted and so tests an override not in effect (later record); the two implementation deviations are accepted; `doctor` reports presence, not the matcher (documented, intake non-goal, later record).

Policy conformance: N/A with the examination recorded; `surfaces.policy` is false and no policy text change is owed. Infrastructure: N/A. `surfaces.accessibility` is true; the accessibility review applied `.ai/rules/accessibility.md` directly because the waived specify phase recorded no accessibility requirement, which the gate advises on.

## Residual risk
Three conditions are left undischarged in `evidence.yml`, so `change close` refuses until a person confirms each: GDH-1 (the maintainer reads `.ai/harness-evals/README.md` at merge), GDH-2 (the off-mode override text corrected, or the code fix landed first), GDH-3 (the protected header's `off` quoting and scope statements corrected). `residual-risk.md` weighs them and lists what is accepted without a condition: the `cd` plus redirection refusal, the spurious tamper log line, the guard disengaging at `judged`, the unevidenced Grok post-call claim, the README heading structure, the gate test that writes `off` unquoted, and `doctor` not reporting an old matcher. Each of those is a later record's work and none weakens a control.

## What the person does next
1. Let `phase seal judge` commit this directory.
2. Before or at merge, read `.ai/harness-evals/README.md` for REQ-GDH-003 (GDH-1), correct the off-mode override text in `README.md` and `docs/user/guard-hook.md` or land the code fix first (GDH-2), and edit the header of `.ai/policies/enforcement.yml` (GDH-3). The header and the harness-eval note are maintainer edits outside any skill's write set, as `b9f4d7c` was.
3. Run `11-faq-index` after GDH-2 if the FAQ records are to be indexed; `12-observability` owes nothing.
4. `soft-foundry change release` carries GDH-1 to GDH-3 as items; confirm each with `change close --confirm`, a pull-request comment `CONFIRMED: <id>`, or `change discharge` once released.
5. Open one later code record for: the off-mode post-call behaviour (record the baseline in off mode, or skip the post-call check in off mode), the `cd` plus redirection `NoMethodError`, the tamper line with nothing restored, the `judged` disengagement, the unquoted `off` in `test/gate_checks_test.rb`, accepting YAML's boolean `off`, and `doctor` reporting an old matcher. That record revises the README, the user page, and FAQ-GDH-003 where they describe the `cd` defect as current (DOC-F-004).

Learn is waived at low risk; `next` stays `learn` so the runner steps over the waiver.
