# Final Judgment

## Outcome

BLOCKED

The change returns to remediation. Two major review findings leave required failure behavior unmet. This judgment does not accept them.

## Commit judged

`2da13adfd2e776de2b4e0c1d7eb64c3ca20f3e3b` (branch `change/phase-lifecycle-controls`).

That commit records the review. The code the later evidence describes is `529e749851af45073d32327857722660a72c3085` (remediation of the lock race, free-text characters, and `--env` echo). `git diff 529e749..2da13ad -- lib exe test spec infra` is empty. Commits after `529e749` record verification, evaluation, the second attack, and the review.

The specification text on this commit was recorded at `d482a0d46034b14262bbd375efc0e067ecc2c0d0`. Nothing under `02-specification/` changed after that commit. `d482a0d` is an ancestor of `529e749` and of `2da13ad`.

This judgment read the change record through review, and the source of `ChangeRecord::Transaction#commit!`, `ChangeRecord#open_release_items`, `PhaseReopen#reopen`, `Release.lint`, `Cli#change_close`, `Processes#phase_of`, and `releaseSection` in `lib/soft_foundry/ui/assets/app.js`. It did not re-run the suite, the journeys, or the attack drivers, and it did not inject a kill during reopen.

## Requirements status

Required phases are complete: intake, discovery, specification, threat model, plan, implementation, verification, evaluation, attack, remediation, and review. `skipped_phases` is empty. Risk is high, so nothing required was waived. Documentation, FAQ index, and observability are pending and optional in the workflow. That does not close REQ-027; see Documentation.

The ordinary paths evaluation and the second attack drove are in place: reopen resets the downstream set review accepted as D2, a phase-run session is refused for reopen, release, and discharge, parallel preflight refuses a phase outside `isolated_phases`, release requires one approving judgment word and at least one item, and the release/reopen check-then-write now holds the record lock (ATK-001 not reproduced, 14 of 14 pairs, one winner).

Two requirements are unmet.

REQ-022 and AC-017 require the reset and its history entry to land together or not at all. `PhaseReopen` says that in its class comment and then stages every file and renames through `Transaction#commit!`. Metadata is renamed first. The transaction comment records the consequence: a crash between renames leaves a history entry for a reset the handoffs do not show. Staging failure rolls back (`test_a_failure_while_staging_leaves_the_record_byte_identical`). A failure between renames does not. `change close` decides from handoff status and the judgment. It does not compare `phase_reopenings` to those handoffs. On a judged record, a kill after the metadata rename and before the handoff renames leaves verify and everything after it `complete`, so close can succeed on the evidence the history says was reset. That is the failure REQ-022 names. PLAN-005 called the window visible and stopped there. Visibility does not keep close from succeeding. Attack did not run this kill (ATK-006, ATTACK-011). The source order is enough to see that AC-017 does not hold.

REQ-019, REQ-020, REQ-025, and AC-042 treat a discharge as a recorded time. `open_release_items` and the close confirmation use Ruby truthiness of `discharged_at`. `releaseSection` uses JavaScript truthiness. An empty string is discharged in the CLI, in `ci`, and in `change close`, and open in the released table. `Release.lint` does not reject it. A judgment-carried item with `discharged_at: ""` is added to the close confirmation list (`Cli#change_close`). The tool's own `change discharge` writes a real timestamp. The empty string is a hand edit or a partial value, and TB-3 says check and CI detect hand edits. They do not detect this one, and the two surfaces disagree (WCAG 1.3.1, REV-002).

## Verification

Current for the code. Bound to `529e749851af45073d32327857722660a72c3085`. The recorded tree `543e364149a5ab8b3e8873ff9eee4e50dbeb2e77` is that commit's tree. CHECK-001 passed: 784 runs, 6030 assertions, 0 failures, provider keys and the phase marker unset. `soft-foundry check` and `soft-foundry eval` passed (18 passed, 1 skipped). Red commit `053562b` was confirmed for `test/record_lock_test.rb`. The remediation tests have no red commit (VER-002). Prior runs at `4c79227` (failed) and `7342f98` (passed, then stale) are kept under `evidence/` and were not edited.

Implementation's own commit `d2050f61e44b44d5d9dd825c354cf7a520da4bf6` is not current for every code path. `529e749` changed library and test files. Verification, evaluation, and attack after that commit cover the delta.

## Evaluation

Current for the code. Bound to `6357775efd74e706a2955f0f73b00ad0d897f573`, which contains the same library and tests as `529e749`. Journeys EVAL-001 through EVAL-010 passed against throwaway repositories and a stub shell. No journey failed.

EVAL-F1 is the AC-014 wording gap (the gate prints SKIP and exits 0). Review accepted that reading as D3 because REQ-023 keeps a pending gate's meaning, and `change close` still refuses. This judgment does not reopen D3, and it is not a reason for the block.

EVAL-F2, EVAL-F3, and EVAL-F4 are the plain-status, `ci` indent, and parallel `pass` gaps below. The UI was not rendered in a browser.

## Attack

Current for the code. The second run is bound to `1ce44defbcdf87589b6feb6c8b69a8f6ad3733cd`. `c3a971eb6dfd494b48cc06a48ca235205d654eae` rewrites attack evidence only (invisible characters escaped in the captured files) and does not change library or tests.

ATK-001, ATK-002, and ATK-003 were not reproduced. Look-alike letters that are visible still pass `Text.free_text!` and stay scan-clean. ATTACK-011 (held lock, symlink, kill mid-write) was not run; the guard refused commands that named the lock directory. The kill in REV-001 is the case that gap left, and review traced it in the source.

ATK-004 remains. An empty `discharged_at` is the part this judgment blocks on (REV-002). A hand-edited non-empty timestamp with no note is the TB-3 case the threat model already stated. This judgment does not adopt that as a ship decision.

ATK-005 remains the documented marker residual: unsetting `SOFT_FOUNDRY_PHASE` in a shell releases the change, and a forged finished record releases with an advisory. TB-1 and the threat model call the marker a guard against accident.

## Documentation

`README.md`, CLI usage, `.ai/README.md`, `.ai/schemas.md`, and `.ai/workflow.yml` `isolated_phases` name the new commands. `docs/user/README.md` is still the stub and names none of them. The branch adds no harness-eval case for a malformed release block, a non-isolated parallel request, or a stale auto-reopen (REV-004, REQ-027, AC-050). Unit tests cover those refusals, and `soft-foundry check` passes. Harness-eval files were not read here; the skill denies that tree. The diff from the merge base to `2da13ad` does not touch `.ai/harness-evals/` or `docs/user/`.

The document phase is still pending. Remediation cannot write `docs/` or the control plane. REQ-027 stays open for the document phase and for a maintainer who can add the harness cases. It is not why this judgment blocks, and it is not met.

`.ai/schemas.md` describes `previous` as one status. The code stores a map. The timeline does not read `previous`. Operations noted it and filed no current wrong branch.

## Observability

`surfaces.observability` is false. The repository profile records no deployed service. The observability phase is pending and optional, which matches REQ-026's "no metrics infrastructure."

The timeline shows reopens, the automatic label, releases, and discharges. Plain `change status` prints the released line and does not print `phase_reopenings` (REV-005, EVAL-F2). `ps` reports `args[2]` only, so `phase run evaluate attack --parallel` shows as evaluate (REV-007, `Processes#phase_of`).

## Review findings

Reviewed at `c3a971eb6dfd494b48cc06a48ca235205d654eae` on xAI. Implementation and remediation ran on Anthropic. The review prose is committed in `2da13ad`. No blocking review finding. REV-001 and REV-002 are major, and the review said they should be settled before an approving judgment.

This judgment settles them by returning the change. D2 (downstream follows `next` edges only), D4, D5, and D8 stand as the review accepted them. D3 stands with the AC-014 note above. D6 (the `--env` value in shell history and in `ps` until `setproctitle`) stands as the review accepted it. None of those is a reason for this block.

Policy conformance is N/A (`surfaces.policy` is false; privacy, security, and terms are `NOT_APPLICABLE`). Infrastructure is N/A. Accessibility conforms for the source and the captured CLI output that were examined, with REV-002 as the 1.3.1 break on an empty `discharged_at`. The rendered page was not operated with a keyboard or a screen reader.

## Residual risk

See `residual-risk.md`. REV-001 and REV-002 are not accepted. The smaller gaps are listed so the next judgment still has them. This outcome does not sign them off.
