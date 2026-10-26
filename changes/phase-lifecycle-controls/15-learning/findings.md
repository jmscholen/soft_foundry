# Learning

Judgment: APPROVED_WITH_RESIDUAL_RISK at f6b2f2d (code at 030b28f). Three review rounds, two majors that blocked the first judgment (REV-001, REV-002), both closed in remediation.

## What this change taught us
- Ordering of renames in a multi-file commit decides what a crash leaves behind. REV-001: metadata renamed first left history for a reset the handoffs did not show, and `change close` could pass on stale evidence. Handoffs first and metadata last fails closed, because close refuses a pending required phase.
- Fail-closed is not all-or-nothing. After the fix, a kill inside the rename loop still leaves a prefix of pending handoffs, no history entry, and a leftover temp file (REV-008, JUDGE-002). AC-017 as written is not met, and remediation cannot amend the specification.
- A state test written twice drifts. "Discharged" was Ruby truthiness in the CLI and `trim() !== ""` in the page (REV-002, then REV-009). The ASCII-blank fix still leaves U+00A0 split between `String#strip` and `String.prototype.trim` (JUDGE-003).
- Remediation tests were not run red before the fix (VER-002), so they have no red commit.
- Requirements that name documentation and harness-eval cases (REQ-027, AC-050) cannot be met by implementation or remediation, whose write sets exclude `docs/` and `.ai/`. They surfaced as residuals in review and judgment (REV-004, JUDGE-004).

## Reviewer/evaluator/attack findings worth generalizing
- REV-001 and REV-002 (majors): crash ordering, and one definition of "open" across surfaces.
- REV-008 and REV-009: the residuals of those two fixes. A fix to a boundary case needs a sweep of the neighbouring values, not only the reported one.
- ATK-001 (release/reopen race) was not reproduced once the record lock held: 14 of 14 pairs, one winner. The attack phase drove the real concurrency rather than reading the code, which is why the lock was trusted.
- Attack drives 13 and 14 (blank values, kills before renames 1, 2, 3, 6, 7) are what made the second judgment possible. Evidence that injects the failure is stronger than evidence that reads the code.
- Judgment was the first phase to find the REV-001 consequence that mattered (close succeeding on reset evidence). Review had graded it from the code path alone.

## Proposed deterministic checks
- A check that every `discharged_at` / state predicate used by `lib/` has one definition that the UI asset also receives (for example, emitted into the snapshot) rather than re-implemented. See proposed-evals.md.
- None proposed for rename ordering; the crash-injection test already covers it.

## Proposed rule changes
See proposed-rules.md. None self-applied.

## Proposed harness evals
See proposed-evals.md.

## Repeated failure patterns considered
- Pre-existing instincts already cover red-first (`commit-the-failing-test-first`) and regenerate-not-annotate. This change repeated the red-first miss for remediation tests (VER-002), so that instinct is reinforced, not duplicated.
- The write-set gap on docs and harness-eval cases recurs across changes: a requirement lands on a phase that cannot write it. New instinct below.
