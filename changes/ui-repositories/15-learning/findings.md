# Learning

## What this change taught us
- The confusion came from adding a machine-wide view to a single-repository page without changing the page's frame. Each addition was reasonable; together they had two scopes and no label. When a view's scope is wider than the page it sits on, the page has to change, not only gain a link.
- Asking was right. After two misreadings, the options were put to the maintainer with their costs, and the answer took seconds.
- Running the page against the real machine found two faults that 419 passing tests and a syntax check did not. That is the fourth record in a row to note that the page script is untested; it should be the last.
- A catch-all that turns every failure into "Not connected" hid a programming error behind a network message.
- Keeping other people's project names out of a committed record takes deliberate filtering; the evidence scripts now count them and name only what they staged.

## Reviewer/evaluator/attack findings worth generalizing
- REV-002: a finding carried as "minor" across several changes should be re-rated when it causes a fault.
- REV-015: discovery by observation widens the trust boundary to whatever can be observed.

## Proposed deterministic checks
- Run the page script under a headless DOM in the test suite and exercise each view with fixture data.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
