# Final Judgment

## Outcome

**APPROVED_WITH_RESIDUAL_RISK**

REQ-001 through REQ-018 hold on the paths the specification names, at the judged commit. The defect that returned this change for another pass, REV-001, is closed: a parallel run that marks a complete-with-blocking handoff exits 2, the same status a single run returns. Verification, evaluation, attack, and review were recorded again on that code, and each gate passes. The residuals in `residual-risk.md` are accepted for this change. None of them waits on a production observation. `undischarged` is empty.

## Commit judged

`9119e406d33be0823bbc4c95fa79ad2ea7264a4f` on `change/small-process-fixes`.

The last commit that changes `lib/`, `exe/`, `test/`, or `.ai/` is `44efb99d6b1ebb1d73d99811ae036d646c746bf3` (the REV-001 remediation). `git diff 44efb99..HEAD` is empty for `lib/`, `exe/`, `test/`, `app/`, `config/`, `db/`, `spec/`, `infra/`, `.ai/`, and `README.md`. The worktree has no uncommitted change in those paths. `3e356a1` records verification. `e349c99` records evaluation and attack. `9119e40` records review. The specification lock is `01b7304b244d1eb540e6ed558ac41cb3b951d87f`; nothing under `02-specification/` changed after it. Uncommitted edits at judgment time are `metadata.yml` (`current_phase: judge`) and this phase directory. Neither is in the APP, TESTS, or INFRA path groups.

## Requirements status

| ID | Result |
| --- | --- |
| REQ-001 | Met. Spaced `--type` and `--risk` are written into `metadata.yml`. Omitting a flag leaves the template placeholder. EVAL-001 and EVAL-002 passed. |
| REQ-002 | Met for the spaced form. An unknown spaced value is refused before a record exists, and the message names the flag, the value, and the allowed list. EVAL-003 passed. The equals form and a repeated `--type` are REV-002, accepted below. |
| REQ-003 | Met for the shipped vocabulary. One constant is the source. `check` fails when the template comment or the `waivable_by_risk` keys disagree. `change new x --risk high --track iterative` is refused. `soft-foundry check` passed (CHECK-002). REV-006 is the unlinted `tracks.forced_by_risk` key; the shipped workflow agrees (`high: gated`). |
| REQ-004 | Met for an Array-valued `blocking` list. The runner sets `blocked`, keeps the entries, notes the change, and prints `blocked:`. |
| REQ-005 | Met for the specified case. Single runs, parallel runs, and auto-reopened runs mark a complete-with-blocking handoff the same way, and the write is that phase's handoff. A parallel run that performed the mark exits 2 unless a session exited nonzero, HEAD moved, or a finish write failed. `phase run --panel` is outside the sentence; see the panel row in `residual-risk.md`. |
| REQ-006 | Met. A hand-edited `complete` handoff that lists blockers still fails the gate. A failed mark prints `warn:` and leaves the handoff as written. The `warn:` line omits the next step (REV-008). |
| REQ-007 | Met. The adversarial-testing, verification, and review skills and the README content-scan section tell agents to write invisible and control characters as visible escapes or to build them in a script. The scanner is unchanged. The text landed in `cf932d1`. |
| REQ-008 | Met on the recorded shapes. `change summary` prints the stable prefixes from recorded files and does not run the gate. A string or mapping in `blocking` or `findings` is shown as none (REV-003). |
| REQ-009 | Met. An unknown slug is refused with the known names. An unreadable handoff is `unreadable` with a reason, the rest prints, and the exit is zero. EVAL-006 passed. |
| REQ-010 | Met on the journeys and the new lines review read, with REV-008. Outcomes are words, transcripts have no escape bytes, each fact has a prefix, and refusals name the fix. |
| REQ-011 | Met. `.ai/rules/access-control-parity.md` states the in-force requirement, the `access_control` source, and the recorded states. |
| REQ-012 | Met. `protection` and `protection_note` are optional. `disabled` without a note fails. Older records without the fields stay valid when the check does not apply. |
| REQ-013 | Met as specified. When `access_control` is declared and a changed path matches, the gate requires `in_force` or a noted value on every check. The check does not judge whether the claim is true (IMPL-004, the rule's Limits section). |
| REQ-014 | Met. This repository declares no `access_control`, and `protection stated` is skipped. |
| REQ-015 | Met. The diff adds no network call, credential, or privilege. `mark_blocked!` writes only the finished phase's handoff under the record lock. |
| REQ-016 | Met for a runner-marked blocked run, the summary prefixes, and `protection stated`. Those lines are plain text. REV-010 is the session-authored `blocked` tally. |
| REQ-017 | Met. The summary does not construct `Gate`. The empty-record evaluation run finished well under a second. |
| REQ-018 | Met. `surfaces.policy` is false. The diff adds no collection, recipient, retention, or promise. Policy text changes owed: none. |

AC-001 through AC-020 map onto those rows. AC-007, the parallel and auto-reopen marking criterion, holds: the new test writes `status: complete` and `blocking: ["needs a person"]` from the evaluate session and asserts exit 2, handoff status `blocked`, the `blocked:` line, and `phase evaluate: fail`. This judgment re-ran that test at HEAD: 1 run, 6 assertions, 0 failures.

## Verification

Gate `verify` passes at `44efb99d6b1ebb1d73d99811ae036d646c746bf3`. Evidence is current: no application, test, or infrastructure file changed between that commit and HEAD, and the specification is unchanged since `01b7304`. The recorded full-suite tree `fc40a9d1630a14b54a6076ca2c4d63c308e0bc15` is the tree of that commit, outcome `passed` (822 runs, 6228 assertions, 0 failures, 0 errors, 0 skips, with `SOFT_FOUNDRY_PHASE` unset). Red evidence for CHECK-001 holds (`e496c67` contains `test/protection_stated_test.rb`, and an application change follows before `44efb99`). `protection stated` is skipped because the profile declares no `access_control`. CHECK-003 failed when the suite inherited `SOFT_FOUNDRY_PHASE=verify` (VER-001, REV-009). That run is preserved. It is a pre-existing environment coupling, and it is accepted as residual.

## Evaluation

Gate `evaluate` passes at `3e356a192053aea57572f94afa3a15d7563ee647`. Evidence is current. EVAL-001 through EVAL-006 passed on a fresh scratch repository, with no escape bytes in the transcripts. Runner blocked-marking, the parallel exit status, and auto-reopen were left to the verification tests. The parallel exit test is in the suite that passed at `44efb99`, and attack re-ran that file (26 runs, 0 failures).

## Attack

Gate `attack` passes at the same commit as evaluation. Evidence is current. Seven cases denied. Five low violations remain: ATK-001 (REV-003), ATK-002 (REV-004), ATK-003 (REV-005), ATK-004 (REV-002), and ATK-005 (REV-010). ATTACK-012 records that the complete-with-blocking parallel case exits 2, and that a session which writes `status: blocked` itself prints `phase attack: fail` and exits 0. Attack states that none of the five lets a blocker pass the gate or records a lower risk than the one typed. They are accepted below.

## Documentation

`10-user-documentation/` and `11-faq-index/` are optional and still pending. The predecessor check steps over them. The user-facing text for the new commands and the content-scan guidance is in `README.md`, written in `cf932d1` and read by review. The parity rule is `.ai/rules/access-control-parity.md`. There is no documentation-phase output for the index to transform.

## Observability

`surfaces.observability` is false. There is no deployed service. `12-observability/` is optional and still the template. The operator surface for this change is the CLI: `blocked:`, the summary prefixes, and `protection stated`. A runner-marked blocked run prints `blocked:` and exits nonzero on the single-run, auto-reopen, and parallel paths. REV-010 is the remaining split, accepted below: a session that writes `blocked` itself is tallied as fail, and the process exits 0, which is the same exit the single-run path returns for that handoff. The gate treats a `blocked` handoff as a warning.

## Review findings

Gate `review` passes at `e349c99a15080828a9e078ff111cdebad9584f16`. Evidence is current. No finding is above minor, so the findings-explained check passes. Provider `xai`, different from the `anthropic` implement and remediate sessions.

REV-001 is closed. Review re-ran `test_a_session_leaving_complete_with_blocking_is_marked_blocked_and_the_run_exits_nonzero` at this HEAD (1 run, 0 failures). This judgment re-ran it again, with the same result. The earlier judgment's outcome was BLOCKED on that defect. The remediation in `44efb99` is what this approval rests on.

REV-002 through REV-011 are minor. They are listed in `evidence.yml` and `residual-risk.md`, and they are accepted. Infrastructure review is N/A. Policy conformance is N/A, policy text changes owed: none. Accessibility conforms with REV-008.

Also carried, and accepted as stated limits:

- `protection stated` does not check that an `in_force` claim is true (IMPL-004, THREAT-006). The specification and the rule state that limit.
- `phase run --panel` does not call `mark_blocked`. REQ-005 names single runs, parallel runs, and auto-reopened runs. A panel that leaves `complete` with blocking items still fails the gate.
- Harness-eval cases were not added. The plan left them to a phase allowed to read `.ai/harness-evals/`. This phase did not read that tree. Unit and integration tests cover the new behavior, including the parallel exit status. REV-011 is that the new assertion shares a commit with the fix.

DEV-001 and the README half of DEV-002 are present at the judged commit: the parity rule, the three skill paragraphs, the `tests.yml` template comments, the README section, and the `protection` note in `.ai/schemas.md`.

## Residual risk

See `residual-risk.md`. Each open item is accepted by this judgment. Nothing waits on a production observation. `undischarged` is empty.
