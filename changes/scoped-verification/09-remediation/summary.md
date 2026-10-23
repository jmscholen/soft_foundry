# Remediation

## Finding references
Repaired: ATTACK-F-001 (rename collapsed to its destination), ATTACK-F-002 (git.branch repointed to hide staleness), EVAL-F-001 (path claimed by another record enlarged this record's verify size and failed its status), ATTACK-F-004 (case-folded citation slug), EVAL-F-002 (empty reason list in the size line).
Not repaired, by decision: ATTACK-F-003 (an active record declaring `**`; the accepted residual of MIT-003, an advisory by specification, for review and judgment to weigh) and ATTACK-F-005 (recorded size is gated for verification only, which REQ-011 specifies; the empty-list wording part is repaired under EVAL-F-002). EVAL-F-003 and EVAL-F-004 are observations for the accessibility review, not defects.

## Root cause
- ATTACK-F-001: `git diff --name-only` applies rename detection and lists only a rename's destination, so the source path never reached staleness or sizing.
- ATTACK-F-002: the measure used the recorded `git.branch` tip without checking that the tip contains the evidence commit, so a branch lacking the change measured "no change".
- EVAL-F-001: sizing at verify treated every entry not in scope as a reason for the larger size, including paths claimed by another record, which staleness already leaves to that record.
- ATTACK-F-004: the cited slug was joined to a path, and a case-insensitive filesystem resolved a different spelling to the same directory.
- EVAL-F-002: the message built its cause only from path reasons.

## Changes made
- `lib/soft_foundry/git.rb`: every `diff --name-only` uses `--no-renames` (changed_since, changed_between, diff_paths), so both sides of a rename are listed.
- `lib/soft_foundry/scope.rb`, `lib/soft_foundry/gate.rb`: a recorded branch that is not checked out and does not contain the evidence commit fails closed (scoped: measure error; unscoped: a STALE evidence-current failure) naming `git.branch` as the fix.
- `lib/soft_foundry/sizing.rb`: paths claimed by another record no longer enlarge the verify size.
- `lib/soft_foundry/full_suite.rb`: a citation resolves only when the slug equals the directory name exactly.
- `lib/soft_foundry/gate.rb`: the size failure names a cause when no path is one.
- `test/scoped_verification_test.rb`: five regression tests (rename lists both sides; rename out of scope stales; branch lacking the evidence is stale for scoped and unscoped records; claimed path does not enlarge size; citation slug case). Full suite with provider keys unset: 630 runs, 4370 assertions, 0 failures. `soft-foundry check` passes.

No expected outcome or other phase's evidence was edited.

## Evidence invalidated
All commit-bound evidence of verification (06), evaluation (07) and attack (08) is stale: `lib/` changed after their commit_sha values (the gate reports it). The tests.yml full-suite record for 06 names the old tree and must be re-recorded.

## Required reruns
Verification, evaluation and attack (all three, per `transitions`), then review and judgment. Attack should retry ATTACK-013, 014 and 016 and the EVAL-013 journey.
