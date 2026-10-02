# Learning

## What this change taught us
- Opening the real page in a real browser found, in the first minute, a defect the tests had encoded as correct: the cross-site refusal also refused the page. The test was faithful to the design and the design was wrong.
- Running the attack cases against a live process found a denial of service that reasoning had missed: a connection limit without an eviction rule turns a protection into the attack.
- Putting every routing decision in one function that touches no socket made eighteen refusal tests possible with no timing in them.
- A process started in the background of a script does not receive SIGINT. A transcript that needs to stop a server must use SIGTERM, and the Ctrl-C path needs its own check.
- An unrelated `claude` process on the machine looked, for a moment, like something this session had started. Checking its parent and working directory before touching it was the right order.

## Reviewer/evaluator/attack findings worth generalizing
- ATTACK-005: every limit needs a stated behaviour at the limit.
- REV-026: an accessibility evaluation should say what was not exercised as plainly as what was.

## Proposed deterministic checks
- A static check that page scripts contain no markup-parsing API already exists as a test; it could become part of `soft-foundry check` for any governed repository with a UI.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
