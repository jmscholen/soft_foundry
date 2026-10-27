# Final Judgment

## Outcome

APPROVED_WITH_RESIDUAL_RISK

The change proceeds to learning. The residuals below stay unmet. They are named in `residual-risk.md`. They do not return the change to remediation.

## Commit judged

`f6b2f2d31b0297503c3e1b8c50c160e6f46614bf` (branch `change/phase-lifecycle-controls`).

That commit records the third review. The code the later evidence describes is `030b28fb772fdc2cc610d255f3a5e09f35c50f01` (handoffs renamed before metadata, a blank `discharged_at` refused). `git diff 030b28f..f6b2f2d -- lib exe test spec infra` is empty. Commits after `030b28f` record verification, the third evaluation, the third attack, and the third review.

The specification text on this commit was recorded at `d482a0d46034b14262bbd375efc0e067ecc2c0d0`. Nothing under `02-specification/` changed after that commit. `d482a0d` is an ancestor of `030b28f` and of `f6b2f2d`.

The previous judgment, recorded at `da253cc` against `2da13ad`, was a block on REV-001 and REV-002. This judgment replaces it. It read the change record through the third review, and the source of `ChangeRecord::Transaction#commit!`, `ChangeRecord.discharged?`, `ChangeRecord#reached_lifecycle_end?`, `PhaseReopen#reopen`, `Release.lint`, `Cli#change_close`, `SafeWrite`, `Processes#phase_of`, `HarnessEval::STATUSES`, and `releaseSection` in `lib/soft_foundry/ui/assets/app.js`. It read attack `evidence/drive13.txt` and `evidence/drive14.txt` for the two cases the block named. It did not re-run the suite, the journeys, or the attack drivers, and it did not inject a kill during reopen.

## Requirements status

Required phases are complete: intake, discovery, specification, threat model, plan, implementation, verification, evaluation, attack, remediation, and review. `skipped_phases` is empty. Risk is high, so nothing required was waived. Documentation, FAQ index, and observability are pending and optional in the workflow. That does not close REQ-027. See Documentation.

The ordinary paths evaluation and the third attack drove are in place. Reopen resets the downstream set review accepted as D2. A phase-run session is refused for reopen, release, and discharge. Parallel preflight refuses a phase outside `isolated_phases`. Release requires one approving judgment word and at least one item. The release and reopen check-then-write holds the record lock (ATK-001 not reproduced: 14 of 14 pairs, one winner; four concurrent reopens, one history entry).

REV-001 is closed. `Transaction#commit!` stages every file, then renames handoffs in lifecycle order and `metadata.yml` last. A kill before any rename leaves the destinations unchanged. A kill after the first required handoff rename leaves that handoff `pending` and `phase_reopenings` empty. `change close` uses `reached_lifecycle_end?`, so a pending required phase refuses close. Attack drive14 shows that refusal, and shows history staying empty, for kills before renames 1, 2, 3, 6, and 7. The failure the previous judgment blocked on, a history entry for a reset the handoffs do not show and a close that can succeed, does not occur.

REV-002 is closed for an ASCII blank. `ChangeRecord.discharged?` is true for a timestamp or for a string that is non-empty after `String#strip`. `Release.lint` refuses a present blank and names the item. `releaseSection` uses `trim() !== ""`. Attack drive13 shows `""`, spaces, tab and newline, `false`, `0`, `[]`, and `{}` refused by `check` and `ci`, counted open, and refused by `change close`.

Three requirements stay unmet and are residual, not a return.

REQ-022 and AC-017 still ask for the reset and its history entry together, or for the record to be entirely unchanged. A kill inside the rename loop is a third state: a prefix of the handoffs is `pending`, `phase_reopenings` is empty, and `<path>.soft-foundry-tmp` files remain. `SafeWrite.commit_staged` renames one file at a time and does not remove a temp the rename did not consume. Retry names the temp. When every targeted handoff is already `pending`, retry says nothing to reset, and the reason is never stored. Close still refuses, so the stale-evidence path is closed. The letter of AC-017 is not met. Evaluation's EVAL-011 pass is the fail-closed metadata-rename case, not the all-or-nothing sentence. This judgment does not adopt that pass as AC-017 met. Review left the gap as REV-008 and did not ask for another remediation cycle. A journal, or a specification change, is what would close it. Remediation cannot amend the specification.

REQ-019, REQ-025, and AC-042 still disagree for one hand-edited value. A `discharged_at` of only U+00A0 is discharged in Ruby (`String#strip` keeps it) and open on the page (`String.prototype.trim` removes it). Attack drive13: `check` and `ci` exit 0, `change status` reports 0 open items, `change discharge` says the item is already discharged, and `change close` reaches the merge check. The API timeline lists no discharge. The heading count comes from the server, so the page can say 0 open items while the state cell, from `trim()`, says open (WCAG 1.3.1, REV-009). The discharge command writes an ISO-8601 timestamp and cannot produce this value. ASCII blanks agree. A non-blank junk string is discharged on both surfaces and stays the TB-3 residual review already accepted (ATK-004).

REQ-027 and AC-050 still require `docs/user/` and the harness-eval cases. See Documentation.

## Verification

Current for the code. Bound to `030b28fb772fdc2cc610d255f3a5e09f35c50f01`. The recorded tree `896e09dcff2a710994b384298ff6f9c791452753` is that commit's tree. CHECK-001 passed: 786 runs, 6042 assertions, 0 failures, provider keys and the phase marker unset. `soft-foundry check` and `soft-foundry eval` passed (18 passed, 1 skipped). Red commit `053562b` was confirmed for `test/record_lock_test.rb`. The remediation tests have no red commit (VER-002). Prior runs at `529e749` (passed, then stale), `7342f98` (passed, then stale), and `4c79227` (failed) are kept under `evidence/` and were not edited.

Implementation's own commit `d2050f61e44b44d5d9dd825c354cf7a520da4bf6` is not current for every code path. `030b28f` changed library and test files. Verification, evaluation, and attack after that commit cover the delta.

## Evaluation

Current for the code. Bound to `89b40116b816723a93f601a6da454e507f2e693b`, which contains the same library and tests as `030b28f`. Journeys EVAL-001 through EVAL-011 passed against throwaway repositories and a stub shell. No journey failed. EVAL-011 is the rerun of the reopen order and the blank discharge.

EVAL-F1 is the AC-014 wording gap (the gate prints SKIP and exits 0). Review accepted that reading as D3 because REQ-023 keeps a pending gate's meaning, and `change close` still refuses. This judgment keeps that reading.

EVAL-F2, EVAL-F3, EVAL-F4, EVAL-F5, and EVAL-F6 are the plain-status, `ci` indent, parallel `pass`, refusal-echo, and lock-directory gaps in the residual file. The UI was not rendered in a browser.

## Attack

Current for the code. The third run is bound to `89b40116b816723a93f601a6da454e507f2e693b`.

ATK-001, ATK-002, and ATK-003 were not reproduced. Look-alike letters that are visible still pass `Text.free_text!` and stay scan-clean. ATTACK-011 (held lock, symlink, kill mid-write of release and discharge) was not run. The guard refused commands that named the lock directory. Kill-mid-write for phase reopen is ATTACK-018 (drive14).

ATK-007 is REV-009, the U+00A0 discharge. ATK-008 is REV-008, the leftover temp and the lost reason. ATK-004's non-blank hand-edited timestamp remains the TB-3 case. ATK-005 remains the documented marker residual: unsetting `SOFT_FOUNDRY_PHASE` in a shell releases the change, and a forged finished record releases with an advisory.

## Documentation

`README.md`, CLI usage, `.ai/README.md`, `.ai/schemas.md`, and `.ai/workflow.yml` `isolated_phases` name the new commands. `docs/user/README.md` is still the stub and names none of them. `git diff c7229c8..f6b2f2d -- docs/user .ai/harness-evals` is empty, so the branch adds no harness-eval case for a malformed release block, a non-isolated parallel request, or a stale auto-reopen (REV-004, REQ-027, AC-050). `HarnessEval::STATUSES` in `lib/soft_foundry/harness_eval.rb` includes `released`. Unit tests cover the refusals, and `soft-foundry check` passes. Harness-eval files were not read here. The skill denies that tree.

The document phase is still pending. Remediation cannot write `docs/` or the control plane. REQ-027 stays open for the document phase and for a maintainer who can add the harness cases. It is residual. It is not met.

`.ai/schemas.md` describes `previous` as one status. The code stores a map. The timeline does not read `previous`. Operations noted it and filed no current wrong branch.

## Observability

`surfaces.observability` is false. The repository profile records no deployed service. The observability phase is pending and optional, which matches REQ-026's "no metrics infrastructure."

The timeline shows reopens, the automatic label, releases, and discharges. Plain `change status` prints the released line and does not print `phase_reopenings` (REV-005, EVAL-F2). `ps` reports `args[2]` only, so `phase run evaluate attack --parallel` shows as evaluate (REV-007, `Processes#phase_of`). A killed reopen is visible to `ci`, `change status`, and `change close` as a pending phase, and the next write names the leftover temp (REV-008). `check` can still exit 0 on that half-reset record (drive14).

## Review findings

Reviewed at `2be4aff7a95b8a9b17e745d9d07171affce92bfc` on xAI. The review prose is in `f6b2f2d`. Implementation and remediation ran on Anthropic. No blocking review finding. REV-001 and REV-002 do not reproduce. REV-008 and REV-009 are minor. D2, D3, D4, D5, D6, and D8 stand as the review accepted them.

Policy conformance is N/A (`surfaces.policy` is false; privacy, security, and terms are `NOT_APPLICABLE`). Infrastructure is N/A. Accessibility conforms for the source and the captured CLI output that were examined, with REV-009 as the 1.3.1 break on a hand-edited U+00A0. The rendered page was not operated with a keyboard or a screen reader.

## Residual risk

See `residual-risk.md`. AC-017, the U+00A0 discharge split, and REQ-027 are unmet and are the residuals this outcome carries. The smaller gaps are listed so learning still has them. This outcome does not mark any of them met.
