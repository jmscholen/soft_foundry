# Final Judgment

## Outcome

BLOCKED

`phase run --parallel` marks a complete-with-blocking handoff blocked, prints `blocked:` and `phase <id>: fail`, and exits 0. The single-run path and the auto-reopen path exit nonzero for the same handoff. Review reproduced this as REV-001. It is the reason this change returns through remediation.

## Commit judged

`4626e4b79a86f811c1143be7e197b7c2c854b744` on `change/small-process-fixes`.

No file under `lib/`, `exe/`, `test/`, `app/`, `config/`, `db/`, `spec/`, or `infra/` differs between the verification commit `cf932d1f40b7dfad1abaac9be3b72005c15966b6` and this commit. The commits after verification record evaluation, attack, and review. The specification lock is `01b7304b244d1eb540e6ed558ac41cb3b951d87f`; nothing under `02-specification/` other than that phase's handoff changed after it. Uncommitted edits at judgment time are `metadata.yml` (`current_phase: judge`) and this phase directory.

## Requirements status

REQ-001 through REQ-018 and AC-001 through AC-020 were read against the implementation, the verification record, the evaluation record, the attack record, and the review.

Met on the paths the tests and the evaluation ran: type and risk at creation for the spaced flags (REQ-001, REQ-002, AC-001 through AC-003), the vocabulary lint against the template comments and `waivable_by_risk` (REQ-003, AC-004), blocked marking of an Array-valued `blocking` list on the single-run and auto-reopen paths (REQ-004, AC-005, AC-006), the gate still failing a hand-edited complete handoff that lists blockers (REQ-006, AC-008), the invisible-character guidance in the three skills and the README (REQ-007, AC-009; landed in `cf932d1` after implementation recorded DEV-001), `change summary` prefixes, unknown-slug refusal, and unreadable-handoff behavior (REQ-008, REQ-009, AC-010, AC-011), CLI wording and prefixes on the evaluation transcripts (REQ-010, AC-012), the parity rule, the optional `tests.yml` fields, and the structure-only `protection stated` check (REQ-011 through REQ-014, AC-013 through AC-016), no new network call or privilege and a handoff write confined to the phase just run (REQ-015, AC-017), searchable `blocked:` and summary lines (REQ-016, AC-018), summary cost (REQ-017, AC-019), and no change to a published privacy policy, security policy, or terms (REQ-018, AC-020).

Unmet for approval: REQ-005 and the resolved specification question that parallel runs behave like single runs, on the process status. `lib/soft_foundry/cli.rb` returns 2 from the single-run path when `mark_blocked` returns a count (`marked || result.failed? ? 2 : 0`). `parallel_run` calls the same `mark_blocked`, counts `phase_status == "blocked"` as a printed failure, and then returns 0 unless a session status is nonzero, a finish write failed, HEAD moved, or `result.failed?`. A blocked handoff is a warning to the gate, so `result.failed?` is false. `05-implementation/decisions.md` records that a blocked result exits 2 and that the parallel path already counts blocked as a failure. The second half is false. `.ai/rules/general.md` forbids converting a failure into apparent success. The command prints `phase <id>: fail` and `parallel: N phases run, … failed`, and the process status is 0.

`test/phase_run_blocked_marking_test.rb` asserts a nonzero status for the single run and the auto-reopened run. `test/phase_run_parallel_test.rb` has no blocked-marking case. Verification mapped AC-007 onto the suite. That mapping does not cover this exit.

## Verification

Gate `verify` passes at `cf932d1f40b7dfad1abaac9be3b72005c15966b6`. Evidence is current. The recorded full-suite tree `05de602d463c1605cec05972bfb28c1370fbf4c1` is the tree of that commit, outcome `passed` (821 runs, 0 failures, with `SOFT_FOUNDRY_PHASE` unset). Red evidence for CHECK-001 holds. `protection stated` is skipped because the profile declares no `access_control`. CHECK-003 failed when the suite inherited `SOFT_FOUNDRY_PHASE=verify` (VER-001, REV-009). That run is preserved. It is a pre-existing environment coupling. It is open and it is not the reason for this verdict.

## Evaluation

Gate `evaluate` passes at `821f1e8ffc2ad8de1fe70af87eabe048e1ea222f`. Evidence is current. EVAL-001 through EVAL-006 passed. The record states that runner blocked-marking, parallel runs, and auto-reopen were left to the verification tests. Accessibility observations on the non-TTY transcripts match the command-line rules for the journeys that ran.

## Attack

Gate `attack` passes at the same commit as evaluation. Seven cases denied. Four low violations were left unrepaired: ATK-001 (REV-003), ATK-002 (REV-004), ATK-003 (REV-005), ATK-004 (REV-002). Attack states that none of the four lets a blocker pass the gate or records a lower risk. Remediation was not run. Those four stay open. They do not independently block. They are re-judged after REV-001 is fixed.

## Documentation

`10-user-documentation/` and `11-faq-index/` are optional and still pending. The predecessor check steps over them. User-facing text for the new commands and the content-scan guidance is in `README.md`, written in `cf932d1` and read by review. The parity rule is `.ai/rules/access-control-parity.md`. No separate documentation-phase record was produced. That omission does not block. There is no approved documentation-phase output for the index to transform.

## Observability

`surfaces.observability` is false. There is no deployed service. `12-observability/` is optional and still the template. The operator surface specified for this change is the CLI: `blocked:`, the summary prefixes, and `protection stated`. Those lines exist. REV-001 is the detection gap: a parallel blocked run is visible in the log and invisible to a job that reads only the process status. `.ai/rules/observability.md` requires a practical detection path for a material failure. The printed tally is that path, and the process status contradicts it.

## Review findings

Gate `review` passes at `7606451392918adb9fd0f4d60472e3a6f9d9d1c0`. Evidence is current. One finding above minor, and it names its failure. Provider `xai`, different from the `anthropic` implement, verify, evaluate, and attack sessions. Remediation has not run, so there is no remediate provider to compare.

No blocking review findings. REV-001 is major. This judgment requires it to be fixed before any approval. REV-002 through REV-009 are minor. They are listed in `evidence.yml` and `residual-risk.md`. Infrastructure review is N/A. Policy conformance is N/A, policy text changes owed: none. Accessibility conforms with REV-008.

Also carried, and not a reason to block on their own:

- `protection stated` does not check that an `in_force` claim is true (IMPL-004, THREAT-006). The specification and the rule state that limit.
- `phase run --panel` does not call `mark_blocked`. REQ-005 names single runs, parallel runs, and auto-reopened runs.
- Harness-eval cases were not added. The plan left them to a phase allowed to read `.ai/harness-evals/`. This phase did not read that tree. Unit and integration tests cover the new behavior except the parallel exit status.

DEV-001 and the README half of DEV-002 are present in the tree at the judged commit: the parity rule, the three skill paragraphs, the `tests.yml` template comments, the README section, and the `protection` note in `.ai/schemas.md`.

## Residual risk

See `residual-risk.md`. REV-001 is not accepted. The other open items are explicit and do not independently block. Nothing waits on a production observation. `undischarged` is empty.

## What remediation must do

Make `parallel_run` exit 2 when it has marked a phase blocked, the same status the single-run path returns when `mark_blocked` returns a count. Cover it with a test that writes `status: complete` and a non-empty `blocking` list from a parallel session and asserts a nonzero process status, the `blocked:` line, and `phase <id>: fail`. Then the change returns to verify. A code change stales verification, evaluation, attack, review, and this judgment.

The four low attack violations and REV-006, REV-007, REV-008, and REV-009 may be fixed in that same pass or left for the next judgment. They must be accounted for again. They are not accepted here.
