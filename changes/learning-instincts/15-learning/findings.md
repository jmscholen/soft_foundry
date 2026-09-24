# Learning

## What this change taught us
The series of four records that produced this one (runtime-guard, phase-runner, red-green-evidence, learning-instincts) taught six things worth acting on next time, recorded as instincts in `instincts.yml` with their evidence. The strongest is the one this series adopted midway: commit the failing test first, then name it. The others are about the mechanics of binding evidence to commits: check the commit landed, regenerate rather than annotate, measure staleness on the record's branch, prefer the checkout's executable in hooks, branch from the record branch when stacking.

## Reviewer/evaluator/attack findings worth generalizing
- red-green-evidence REV-020: nothing reminded an agent to make the RED commit at implementation time; the instinct `commit-the-failing-test-first` is that reminder in the form an agent can act on.
- phase-runner deviations 1 and 2 (branch-aware staleness; checkout-first hooks): both were discovered by this repository's own tooling refusing something, and both became instincts.
- Three evaluation results files record a discarded first transcript; the instinct `regenerate-evidence-never-annotate` is the rule the three followed.

## Proposed deterministic checks
- A `red_commit` reminder in the implementation log template (red-green-evidence REV-020).
- A count of instincts awaiting promotion in `change status` (this change's REV-020).

## Proposed rule changes
See `proposed-rules.md`. The instincts above the threshold are the proposals; `soft-foundry learn promote` in a later change is how they reach `.ai/rules/learned.md`.

## Proposed harness evals
See `proposed-evals.md`.
