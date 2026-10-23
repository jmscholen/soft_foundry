# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
`604120cff228371bd4dad01b5dbe8354c6219227`

No file in the application, test, or infrastructure path groups differs between the verification commit `fb0bff73d47b9d0931cc34b6cf6f823e7d0e852a` and this commit. The two commits after verification record the evaluation, the attack, the review, this direction, and two README sentences. The specification has been locked since `3ef23549bb40`.

## Requirements status
REQ-001 through REQ-026 were read from `02-specification/requirements.yml`. The ordinary paths hold, and the suite at `fb0bff7` names AC-001 through AC-022, including the specification re-record assertion in `test/scoped_verification_test.rb`.

These do not hold for every input the attack demonstrated:

- REQ-003 and REQ-004 fail for the decoy-branch procedure in REV-001. A scoped record and an unscoped record both stay current after code lands on the checked-out branch. REQ-004's promise that an unscoped record is decided exactly as before therefore fails for that procedure.
- REQ-003's claimed-path rule is what REV-003 uses. An active record scoped `**` claims every path, so another record's unclaimed-path staleness does not fire. That matches the locked sentence and the remaining risk MIT-003 left to judgment. It is accepted below, not treated as repaired.
- REQ-005 holds for a real stacked branch. ATTACK-021 stays current while code lands only on the branch above, and goes stale when the record's own branch moves.
- REQ-009's locked sentence still says a path outside the declared scope sizes the full suite at verify. The maintainer superseded that sentence for paths another active record claims. `.ai/policies/check-sizing.yml` and the README sizing paragraph say so. An unclaimed path still sizes full. The locked specification file was not edited.
- REQ-011 holds. The gate refuses a smaller size on verification evidence only. Evaluation and attack sizes are recorded and not compared. That is the requirement's own limit (ATTACK-F-005).
- REQ-016 holds when git cannot resolve a commit, a tree, or a branch on the scoped path (EVAL-009). A `git:` value that is a string raises `TypeError` and exits 1 with `String does not have #dig method` (REV-004). The gate does not pass. The message does not name the field or the next step.
- REQ-021 and REQ-022 are present and tagged `category: accessibility`. Review found the CLI and the browser text conforming. The go-live advisory still warns that no accessibility requirement exists. The file does not parse as YAML: the unquoted statement of REQ-016 contains `fail closed:` and `YAML.safe_load` stops at line 81. The advisory loader swallows that error and sees no requirements. The tags are in the file.

`soft-foundry gate all` on this worktree: intake through review pass. Documentation, FAQ index, and observability are pending and optional. Nothing is waived. The track is `gated`, which is what risk `high` forces.

## Verification
Complete and current at `fb0bff73d47b9d0931cc34b6cf6f823e7d0e852a` (tree `537d8d15a7e30f9008b1015e69432753809fabd0`).

The full suite was run twice with provider keys unset. Run 1 failed: `ProcessesTest#test_finds_a_real_running_process` (635 runs, 1 failure). Run 2 on the same tree passed (635 runs, 4396 assertions, 0 failures). The failing test also passed alone. Both logs are kept. `tests.yml` records `outcome: passed` for run 2. The gate's full-suite line is that record, and it passes. `check`, `ci`, and `eval` pass (18 harness cases passed, 1 live case skipped). `red_commit` `8287d58` for `test/scoped_verification_test.rb` is an ancestor, and the file exists there. This record declares no scope, so the size check is skipped and the computed size is the largest, `full_at_verify`, which is what `tests.yml` records.

The cause of the process-test failure was not shown. It is unrelated to this diff on the evidence in the log (a spawned `soft-foundry ui` was not listed by `ps` within 4 seconds while the suite was loaded). It is not a residual of scoped verification.

## Evaluation
Complete and current at `ea50ad589eb0ac2d3a61a5899b1ad9d23029757d`. Thirteen journeys, EVAL-001 through EVAL-013, pass against throwaway repositories. They cover AC-001 through AC-005 and AC-007 through AC-020. AC-006 was left to the suite and to ATTACK-021. EVAL-013, a claimed path no longer failing another record's size check, still passes after the REV-002 decision.

No browser, keyboard pass, or screen reader was driven (EVAL-F-002). The accessibility review reached conformance from `app.js`, `app.css`, the CLI, the size-output test, and these observations.

## Attack
Complete and current at `7ca42a176a3a79baa30e58063dcaeabe1908661a`. The drivers ran the checkout with `ruby -Ilib exe/soft-foundry` in throwaway repositories. This judgment read `results.md` and the transcripts. It did not re-run the drivers.

Denied, and still denied on the third rerun: ATTACK-001 through ATTACK-011, ATTACK-013, ATTACK-014, ATTACK-016, ATTACK-017. ATTACK-021 (a real stacked branch) behaves as designed. ATTACK-018 does not pass; it crashes (REV-004).

Still violated:

- ATTACK-019 and ATTACK-020 (`transcript3.txt`, `transcript4.txt`). `git.branch: frozen` is already in the evidence commit, the ref does not exist yet, phases complete, `frozen` is created at that later commit, then `lib/a/x.rb` lands on the checked-out branch. `gate verify` exits 0 for scope `lib/a/**` and for an unscoped record. Evidence current says `no code changes since … on branch frozen`. The size check and the full-suite record check pass with it.
- ATTACK-015. An active sibling scoped `**` keeps another record's evidence current after `lib/other/x.rb` lands, and the verify gate exits 0. Closing the sibling makes the same change stale. Status `abandoned` still claims.

## Documentation
Phases 10 and 11 are pending. Both are optional, and neither was waived. The user-facing contract is the README section "Scoped verification", including the three known limits added in `604120c`. Those sentences cover the decoy branch (REV-001), an active `**` record (REV-003), and the verify-only size check (ATTACK-F-005). They do not spell out the scalar `git:` crash (REV-004) or a stack cut from a tip equal to the evidence commit (REV-006). Those two are accepted in `direction.md`.

## Observability
Phase 12 is pending. It is optional. `surfaces.observability` is false, and the change adds no deployed service. The operator signal is the gate and status text (REQ-018, REQ-020): applied scope, causing paths, and a reason on each line. That signal follows `tip_for`, so under REV-001 it reports the frozen branch as current. Under REV-004 the command exits 1 with a Ruby error and no next step. Both are the residuals below, not a missing dashboard.

## Review findings
Review is complete and current at `8575131b467d81c15b6773696225499aa576c29e`. It names two findings above minor, and each names its failure. The handoff's `next` is `remediate` because REV-001 is blocking. Functional, architecture, security, and operations do not conform, for that finding. Accessibility conforms. Policy conformance is N/A (`surfaces.policy` is false; each published policy in the repository profile is `NOT_APPLICABLE`). Infrastructure is N/A.

| ID | Severity | Disposition |
| --- | --- | --- |
| REV-001 | blocking | Accepted residual. Same defect as ATTACK-F-007, ATTACK-019, ATTACK-020. |
| REV-002 | major | Closed before this review. Claimed paths do not raise verify size. The shipped policy and README match. The locked REQ-009 sentence is superseded for those paths only. |
| REV-003 | major | Accepted residual. Same defect as ATTACK-F-003, ATTACK-015. |
| REV-004 | minor | Accepted residual. Same defect as ATTACK-F-008, ATTACK-018. |
| REV-005 | minor | Closed in `fb0bff7`. The README states the `git.branch` rule. |
| REV-006 | minor | Accepted residual. |

The acceptance of REV-001, REV-003, REV-004, and REV-006 is the maintainer's decision in `direction.md`, committed by the maintainer in `604120c` after the review. This judgment agrees. The change is not returned to remediation.

Security review is right that, at review time, the remediation summary had named the REV-001 hole and that was not yet an approved exception. The exception is the later maintainer decision. It does not make the security review conform. It records the non-conformance as residual risk.

## Residual risk
See `residual-risk.md`. Nothing is undischarged. Nothing waits on a production observation before close.

The outcome is APPROVED_WITH_RESIDUAL_RISK because the required phases pass and are current, the ordinary acceptance criteria hold, and the open holes are named, bounded, and accepted. A clean approval would hide REV-001, which still lets the verify gate exit 0 after code changes, including for a record with no scope. Returning the change to remediation would reopen a fix the maintainer closed after the ancestry rule could not separate this procedure from a stacked branch (ATTACK-021) without a new recorded fact. That fact, whether `git.branch` resolved at the evidence commit, is owed in a separate change.
