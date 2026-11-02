# Learning

## What this change taught us
- **A structural check is only as strong as the signal it reads, and the signal is always something a committer can write.** The `commit_sha` rewrite was closed three times (ATK-001 uncommitted rewrite, ATK-010 hand-committed handoff, ATK-014 forged `Record` subject) and each fix moved the forgeable signal one step without removing it. The honest end state is a named residual risk with a follow-up (a tool-written trailer), not a fourth round. Record the boundary in the threat model first, so each round is judged against it.
- **Every remediation was itself attacked and every round found something.** Four attack runs over the same code produced ATK-001 to 009, then ATK-010 to 013, then ATK-014 to 018. Plan for the rerun: a remediation that adds a check should ship with the "what does a hand edit of this new signal do" case written down.
- **Performance regressions arrive from correct fixes.** The ATK-010 fix added a second `git log` per phase and the gate already re-read HEAD per check; `gate all` went to 3.2 times the old wall time (EVAL-017). It was caught at evaluation only because REQ-036 put a number on it. Measure git call counts in the implementing session when a check touches git.
- **Sealing a phase with the tool found defects in the tool.** `phase seal remediate` set the wrong next phase (REM-004) and the first seal of implement failed on an inherited `GIT_INDEX_FILE` from the pre-commit hook. Use the new mechanism on the change that introduces it as early as possible.
- **Two fresh sessions in one worktree at once is fragile.** Evaluate and attack run in parallel were killed (exit 137) twice; evaluate alone passed twice. The suite's temp-dir glob (VER-003) fails the same way when suites overlap. The cause of the 137 is not proven; serial runs worked.
- **A judgment gate failure is fixed by redoing the phase.** The first judgment named a verdict but left two uncovered criteria unexplained; reopening it with the gate's reason in the handoff produced a passing rerun without editing evidence.

## Reviewer/evaluator/attack findings worth generalizing
- ATK-001, ATK-010, ATK-014, REV-001: the forgeable-signal chain above.
- EVAL-017: a performance bound in the specification caught a cost no test would have.
- EVAL-018: a failure line that names the problem but not the next action fails a requirement; check the wording of every refusal.
- ATK-004, ATK-005, ATK-013: substring and "not blank" tests are too loose for acknowledgements and reasons; match whole ids and require content.
- ATK-016: a malformed policy file crashes a command instead of naming the file. Parse configuration defensively and name the path.

## Proposed deterministic checks
- `check` could refuse a malformed `enforcement.yml` shape (a scalar `guard`, a top-level `mode`) with the file named (ATK-016).
- `phase seal` could refuse "already sealed" when no `Record` commit exists for the phase (ATK-017).
- A seal trailer written only by the tool, which the recorded-commit lookup requires (ATK-014).

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
