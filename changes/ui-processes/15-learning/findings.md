# Learning

## What this change taught us
- The first delivery was wrong in the way that matters most: it answered a narrower question than the one asked, and every check passed, because the tests, the staged evaluation, and the review were all built from the same misreading. The evidence that would have caught it was on the machine the whole time: five sessions in other terminals, none of them in the list. Looking at the maintainer's actual situation, not a staged one, was the missing step.
- "Multiple sessions" was taken as confirming the reading already chosen. A two-word clarification is a signal to re-read the request, not to proceed.
- A limit written as a non-goal ("sessions not started through soft-foundry") deserved a question before it was accepted: it excluded the thing most likely to be meant.
- The record already held the fact needed to detect a dead session (`executed_by` with a start and no finish); it only needed comparing with what is alive.
- Treating a command line as hostile input from the start made the rule simple: report fields, never the line. The spoofed process in the attack then had nothing to carry.
- Evaluating "what is running" needs things running. Stand-in shells that only sleep, started under their real names, exercised everything except a real session's behaviour.

## Reviewer/evaluator/attack findings worth generalizing
- REV-013: each new view of a local tool widens what its unauthenticated page reveals; say so each time rather than leaning on the first acceptance.

## Proposed deterministic checks
- None new.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
