# Remediation

## Finding references
- REV-001 (major), the reason judgment returned BLOCKED: `phase run <a> <b> --parallel` marks a complete-with-blocking handoff blocked, prints `blocked:` and `phase <id>: fail`, and exits 0. REQ-005.

## Root cause
`parallel_run` called `mark_blocked` and discarded its result. Its exit status came only from session statuses, a failed finish write, HEAD movement, and `Gate#failed?`. A blocked handoff is a gate warning, so none of those fired. The single-run path already returned 2 when `mark_blocked` returned true. The note in `05-implementation/decisions.md` that the parallel path already counted blocked as a failure was true of the printed tally only, not of the process status.

## Changes made
- `lib/soft_foundry/cli.rb` `parallel_run`: records whether any phase was marked blocked and returns 2 in that case, the same status the single-run path returns. Session, HEAD-moved, and write-failure statuses still take precedence.
- `test/phase_run_parallel_test.rb`: new case where the evaluate session writes `status: complete` with a non-empty `blocking` list. It asserts exit 2, handoff status `blocked`, the `blocked: evaluate has 1 blocking item(s)` line, and `phase evaluate: fail`.

Not changed, and still open for the next judgment: REV-002 through REV-009 and ATK-001 through ATK-004 (REV-003, REV-004, REV-005, REV-002). No evidence or expected outcome of another phase was edited.

## Evidence invalidated
This is an implementation change. Verification, evaluation, attack, review, and judgment evidence are stale at the new commit.

## Required reruns
Verify, then evaluate, attack, review, and judge. The parallel-run exit status should be exercised in evaluation.
