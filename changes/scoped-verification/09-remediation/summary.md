# Remediation (round 2)

## Finding references
Repaired: ATTACK-F-006 (the ATTACK-014 variant: `git.branch` repointed to an ancestor of HEAD that still contains the evidence commit hides later code changes, scoped and unscoped).
Carried from round 1, unchanged: ATTACK-F-001, ATTACK-F-002, ATTACK-F-004, EVAL-F-001, EVAL-F-002 repaired earlier and verified fixed by attack; ATTACK-F-003 (an active `**` scope) and ATTACK-F-005 (size gated at verify only) stay as specified, for review and judgment to weigh.

## Root cause
The round 1 repair only required a non-checked-out recorded branch to contain the evidence commit. A branch created at the evidence commit (behind HEAD) satisfies that, and "after" was then measured on that tip, so every later change was invisible. A branch behind HEAD is also the legitimate stacked-branch case, so ancestry alone cannot tell the two apart; what differs is that the declaration was edited after the evidence.

## Changes made
- `lib/soft_foundry/scope.rb`: `Scope.branch_edit(record, git, sha)` compares `git.branch` in the record's `metadata.yml` at the evidence commit with the current file. A difference is a stale cause, `declaration changed: git.branch`. A branch not recorded at the evidence commit is not an edit unless it now names an existing branch other than the checked-out one. `measure` adds it as a declaration entry, so scoped staleness and sizing both see it.
- `lib/soft_foundry/gate.rb`: an unscoped record also goes stale on that edit.
- `test/scoped_verification_test.rb`: regression test (a branch created behind HEAD, later code change, scoped and unscoped records both stale). Full suite with provider keys unset: 632 runs, 4393 assertions, 0 failures. `soft-foundry check` passes.

No expected outcome or other phase's evidence was edited.

## Evidence invalidated
Verification (06), evaluation (07) and attack (08) evidence is stale: `lib/` changed after their commit_sha values. The tests.yml full-suite record for 06 names the old tree and must be re-recorded.

## Required reruns
Verification, evaluation and attack (per `transitions`), then review and judgment. Attack should retry ATTACK-014 with a branch at the evidence commit, and the stacked-branch case.
