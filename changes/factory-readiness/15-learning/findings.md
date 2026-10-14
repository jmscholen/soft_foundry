# Learning

## What this change taught us
- **Block mode showed what warn mode had hidden.** The guard had been in warn mode through thirty changes. The first fresh-context verification under block mode could not run the test suite or the tool from the shell (REM-001), the orchestrating session could not launch the next phase, and a remediated phase could not be rerun. None of this was new; warn mode had reported it to a log nobody read. A control that only warns is not yet a control, and the first block-mode run of a lifecycle is a test of the lifecycle itself.
- **A name-based shell check cannot be completed, only backed.** Four attack rounds (REM-002 to REM-005) each closed the spellings found (`cd`, globs, symlinks, braces, `cd ..`, leaving the root, unresolvable tokens) and the next round found more (quoted segments, `CDPATH`, `find -exec`). The control that held was not a better parser but a different kind of check: record the guard's own configuration before a shell call and restore it after (REM-004). What remains after that is the same-user-with-a-shell residual the repository had already accepted with panel mode.
- **Put the baseline where it is consumed.** REM-005 kept a baseline for thirty minutes so an overlapping call could not re-baseline over a tamper; the next evaluation showed that a baseline recorded by an Edit or Read, with no post-call check of its own, then reverted the maintainer's own edit (EVAL-F7, REM-006). A pre/post pair must be recorded by exactly the call type whose post-check consumes it.
- **The lifecycle ran itself, and that is the result.** Verification, evaluation, attack, review, and judgment all ran in fresh `claude` sessions through `phase run`, six rounds of evidence in all, and every round found something the previous one had not: the shell-naming defect (verification), two bypass classes (attack), a regression in the fix (evaluation), and the owed documentation (review). The record is long because the gate said no six times. That is the first time in this repository's history that it has.
- **The gate had never said no because it rarely ran.** Twenty-five of thirty closed records waived judgment with a sentence. Binding waivers to risk and making judgment unwaivable (REQ-FR-007) is a one-line policy; the harness eval `judgment-waived` now proves the gate refuses it.
- **A tool decodes escapes before the shell sees them.** Two files gained a real zero-width space because the backslash-u escape for U+200B in a tool call's text was decoded by the tool, and the control-plane scan refused them. Anything invisible or secret-shaped that a case needs is built at run time from a token.
- **Writing the control plane from inside the lifecycle is now the maintainer's act.** Under block mode no skill may write `README.md`, `.ai/policies/`, or the hook settings, and the guard refuses to let a session create the override that would allow it. The owed README text and `hooks install --claude` rerun are listed in `09-remediation/summary.md` and are the judgment's condition of approval. This is the designed boundary, and it bit the change that designed it.

## Reviewer/evaluator/attack findings worth generalizing
- ATK-F1/F2/F5/F8: any check that works by recognising names in free text has an unbounded set of spellings; pair it with a check on the state the names protect.
- ATK-F6: a hook that raises exits 1, and the host treats anything but 2 as allow. A guard decides or refuses; it never raises.
- EVAL-F7: a corrective control must distinguish a change made by the guarded call from a change made by the person between calls, and the only reliable discriminator is the call boundary itself.
- REV-001: a control that depends on an installed hook entry must be reported by `doctor` when the entry is missing, or the repository believes it has a control it does not.
- ATK-F12: when a repository is its own harness, the implementer can edit the guard it runs under; fresh-context review and attack are the only check, and they found it.

## Proposed deterministic checks
- `doctor` reports a missing PostToolUse entry (the post-call restore) and a PreToolUse matcher that lacks `Grep|Glob`, with the `hooks install --claude` command to fix it (REV-001).
- `check` warns when a change record's `skipped_phases` is non-empty and `risk` is unclassified, before the gate does.
- `phase run` sets a complete-but-stale phase's handoff to `in_progress` when it begins the rerun, so a crash mid-rerun does not leave a complete handoff over half-regenerated evidence.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
