# Learning

## What this change taught us
- The request was three sentences and the first was a complaint. Treating "is this too much to ask" as a specification ("every reference is a link"), and then folding the two follow-ups in as they arrived, produced the right thing in one pass.
- A page-only change with no runner leaves nothing to write a failing test against. That is a reason to get the page a runner, not a reason to skip the test; this record says plainly that it has no RED commit.
- A count over the source (link makers versus plain anchors) is a cheap guard that a convention holds across a large file.

## Reviewer/evaluator/attack findings worth generalizing
- REV-005: "page-only" is where the untested-script finding bites hardest.

## Proposed deterministic checks
- The reference count in `06-verification/evidence/references.log` could become a test.

## Proposed rule changes
None new; the two from ui-repositories stand.

## Proposed harness evals
See `proposed-evals.md`.
