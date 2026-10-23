# Remediation (round 3)

## Finding references
Repaired: REV-001 (blocking; ATTACK-F-007, ATTACK-017, ATTACK-019 and the scoped variant): a recorded `git.branch` that exists, or is created later at the evidence commit, no longer lets later code go unmeasured.
Resolved by maintainer decision, behaviour kept: REV-002.
Not part of this round (direction.md): REV-003, REV-004, REV-005.

## Root cause
REV-001: `Scope.tip_for` measured "after" on the recorded branch's tip whenever that branch existed and was not checked out. A branch recorded before it exists and then created at the evidence commit passes the ancestry and declaration-edit checks (the declaration never changed), and its tip is the evidence commit, so every later commit on the checked-out branch was invisible. A branch legitimately behind HEAD (stacked) cannot be told from that by ancestry or metadata.

REV-002: a path claimed by another active record's scope does not raise this record's verify size. That is the intended per-change-scope behaviour, so there is no defect, only a text that still says otherwise.

## Changes made
- `lib/soft_foundry/scope.rb`: `Scope.tip_for(record, git, sha)` returns the recorded branch's tip only when that branch is HEAD's own (HEAD is then the measure), its tip equals or descends from HEAD, or its tip strictly descends from the evidence commit (the branch the record really lives on: the commit recording the handoff always follows the evidence commit). Otherwise (at, behind or off the evidence commit, missing) the measure is the checked-out HEAD. A change stacked under another keeps its own branch as the measure, as before (test/stacked_branch_test.rb passes unchanged); a branch created later at the evidence commit no longer hides later code. `gate.rb` passes the sha. The earlier `branch_edit` repair stays.
- Residual: a branch created at a commit after the evidence (for example the handoff-recording commit) without any edit to `git.branch` after the evidence is indistinguishable from a legitimate stacked branch by ancestry; it is not claimed repaired. A first attempt that measured at HEAD for every branch behind HEAD broke the stacked case and was replaced by this rule.
- `test/scoped_verification_test.rb`: `make_record` takes `branch:`. New tests: a branch created later at the evidence commit does not hide later code (scoped and unscoped); a record stacked under another change is measured on its own branch (current, then stale after a commit on its own branch); a recorded branch ahead of HEAD is the measure. Updated: the branch-lacking-evidence test now asserts only that the record is stale, since a branch off the evidence commit is measured at HEAD; the sizing test for a non-checked-out branch now has the sibling claim `lib/other/**`. The existing `test_a_path_claimed_by_another_record_does_not_enlarge_the_size` fixes the REV-002 behaviour.
- Verified with provider keys unset: full suite 635 runs, 4396 assertions, 0 failures, 0 errors (an earlier run of the first-attempt rule had 3 failures in test/stacked_branch_test.rb, which is why the rule changed). `soft-foundry check` passes.

## REV-002 record
REQ-009's text ("a diff outside the declared scope is the full suite") is superseded for claimed paths: a path claimed by another active record's scope does not raise this record's verify size. An unclaimed path still sizes full. The specification is locked and was not edited. `.ai/policies/check-sizing.yml` and the README sizing paragraph still carry the old wording; the maintainer will correct both (this phase cannot write them).

## Evidence invalidated
Verification (06), evaluation (07), attack (08), review (13) evidence is stale: `lib/` changed after their commit_sha values. Attack's ATTACK-017/019 transcripts describe the old measure.

## Required reruns
Verify, evaluate, attack, then review and judgment. Attack should retry ATTACK-014, 017, 019 and the scoped variant, and the stacked-branch case (note it is now measured at HEAD).
