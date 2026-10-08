# Final Judgment

## Outcome
**APPROVED_WITH_RESIDUAL_RISK**

## Commit judged
`92e9bd356b977a4ca82be679d848e94db3c02fb5` (branch `change/session-ledger`, HEAD when this judgment was written).

Application and test code are unchanged since the remediated commit `93acd89`. `git diff --stat 93acd89..92e9bd3 -- lib exe test` is empty, and so is `742dbd4..92e9bd3` for those paths. `92e9bd3` only adds the review write-up and `metadata.yml`. The worktree has no uncommitted changes under `lib/`, `exe/`, or `test/`. See `evidence.yml`.

This judgment also read `SessionLedger.resume_command`, `entries`, `update`, and `default_path`, the Grok argv in `PhaseRunner`, and `recordedSection` in `app.js`, against the review's claims. No application file was edited.

## Requirements status
REQ-SL-001 through REQ-SL-015 and AC-001 through AC-015 are implemented. Verification maps each criterion to a test (AC-015 to `soft-foundry check` plus the README and schema text). Evaluation ran the live journeys that can be run on this machine. Review re-read the code and did not reject a criterion. Conforms. No acceptance criterion is left open, and `undischarged` is empty.

## Verification
**Disposition: passed, current for the judged code.** Bound to `93acd899cc20cb4c25bc7ffe38d374925c2920fa`, the second run, after REM-001. The first run, at `98b55d1`, was superseded rather than annotated. CHECK-001: 466 runs, 3,109 assertions, 0 failures. RED evidence: `d278ecf` (the feature) and `88eee99` (the Grok `-p` argument order) both fail as intended, and code changed after each. `soft-foundry check`, syntax checks, `soft-foundry ci`, and `soft-foundry scan` passed. A 5,000-entry ledger recorded a prompt in 0.197 to 0.217 seconds. The Codex branch of AC-012 is a stubbed launcher and a seeded ledger, not a live turn.

## Evaluation
**Disposition: passed, with one journey not run live.** Bound to `93acd89`. EVAL-001 through EVAL-005, EVAL-007, and EVAL-008 passed, including a live Claude Code resume, a live Grok resume, the change page's recorded-sessions list, and a live `phase run --shell grok` that launched `grok -s <id> --always-approve -p <prompt>` and stored that id. EVAL-006 did not run: Codex 0.139.0 could not refresh its login. That limit is the one the specification already recorded. EVAL-OBS-001 (resume command glued to the prompt) was fixed in REM-001 and is visible in `app.js` as its own line.

## Attack
**Disposition: passed, current, no violations.** Bound to `93acd89`. Eight cases, ATTACK-001 through ATTACK-008, all denied, on a local throwaway directory with synthetic data. ATTACK-001: a folder name with quotes and command substitution was shell-quoted, and five session ids carrying shell syntax were not recorded. The same pass confirmed the known residual that an unmapped Grok tool name is not guarded (TM-001). FIND-ATK-001 and FIND-ATK-002 are fail-safe behaviors now stated in README, not violations.

The attack handoff says this pass was the same interactive session that implemented the change, not a separate attacker. Review then read the code and the transcript independently. That limit is recorded below; it is not a reason to discard the artifacts.

## Documentation
`10-user-documentation` and `11-faq-index` are `pending`. Both phases are optional, and this change did not start them. That is not missing user-facing text. REQ-SL-015 and AC-015 put the description in README, help text, and `.ai/schemas.md`. Review checked those words against the code, including the 1 MB skip and the control-character folder case. The unstarted phases are accounted for. They are not a documentation hole.

## Observability
`12-observability` is `pending` and optional. `surfaces.observability` is false. The repository profile marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE: there is no deployed service. The new failure mode is the one REQ-SL-005 requires, a hook that stays silent and exits 0. The specified signal is that `sessions` shows nothing new and `doctor` reports whether the hook is installed. Review's operations note agrees. No production alarm is owed. Accounted for, not a gap.

## Review findings
`13-review` is complete at `742dbd4` (prose committed in `92e9bd3`) with **no blocking findings**. Seven findings, none of which fail a locked criterion:

- REV-SEC-001 (major). A resume command shell-quotes the folder and interpolates `session_id` raw. `record` refuses an id that is not a plain identifier, and ATTACK-001 confirmed that for hook payloads. `entries` returns any JSON object that has a `session_id`, and `update` rewrites those objects without checking the id again. A same-user writer can plant an id that makes a pasted command do more than resume. Other users cannot write the 0600 file. Confirmed in `SessionLedger.resume_command`.
- REV-SEC-002 (minor). `SOFT_FOUNDRY_SESSIONS`, when set, is used as given. A relative value is the project directory, and `update` chmods a parent this user owns to 0700. README names the variable and does not state that limit. The default path is still `~/.soft-foundry/sessions.jsonl`.
- REV-FUN-001 (minor). `soft-foundry session` with any subcommand other than `log` exits 0 and prints nothing.
- REV-FUN-002 (minor). `phase` usage text still says `--shell claude|codex`. Help text and the runner accept `grok`.
- REV-A11Y-001 (minor). Truncation is marked only with a non-ASCII ellipsis, so the cut disappears if non-ASCII characters are stripped.
- REV-A11Y-002 (minor). `resume` prints the command and no status word, including when the folder is gone.
- REV-ARCH-001 (minor). Implementation wrote `.ai/schemas.md`, `.ai/templates/handoff.yml`, and `README.md` outside its write set. Review accepts the exception because REQ-SL-015 requires those words and no skill can write them. The maintainer still accepts the control-plane edit at merge.

Accessibility and policy results are go-live advisories. No policy text change is owed, and `human_decisions` stays empty. Infrastructure is N/A.

## Residual risk
See `residual-risk.md`. The items a maintainer is accepting by merging are the unquoted session id on the way out of the ledger (REV-SEC-001), an unconstrained `SOFT_FOUNDRY_SESSIONS` (REV-SEC-002), no live Codex capture (EVAL-006), an unmapped future Grok tool name (TM-001), and the smaller command, accessibility, and permission-exception items above.

## Reasoning
Every required phase is complete, and the three optional phases that were not started are optional in `.ai/workflow.yml` and do not leave a specified requirement unmet. Verification, evaluation, and attack describe `93acd89`, which is the application code at the judged commit. Review describes that same code. Implementation's own commit, `98b55d1`, is not current for every code path: `93acd89` changed `phase_runner.rb`, `app.js`, a test, and README. That delta is REM-001, and the later phases re-ran against it. The specification body has not changed since it was recorded; only handoff timestamps moved.

`BLOCKED` would be the outcome if a locked criterion or a specified mitigation were unmet, or if review had returned blocking findings. AC-010 and MIT-001 are met on the path they name: a bad id in a hook payload is not recorded, and the folder is shell-quoted. ATTACK-001 denied that attempt. The ledger-file trust boundary treats the owning user as the trusted side. REV-SEC-001 is a real paste-boundary gap beyond that specification, and review left it for this judgment to fix or accept. It is accepted here, not sent back, because it does not falsify the criterion and it is not a cross-user bypass. It is also not absorbed silently: it is the first residual, with the fix owed to a follow-up.

`REJECTED` does not fit. The specification is sound, the implementation matches it, and the attack pass found no violation.

`APPROVED` does not fit either. REV-SEC-001 is a major, confirmed injection on a command people are told to paste, if the ledger line did not come from `record`. A maintainer should merge knowing that, which is **APPROVED_WITH_RESIDUAL_RISK**.
