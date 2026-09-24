# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against real scratch repositories carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process: a feature done test-first can bind its RED and GREEN commits to its verification and the gate passes naming them; each way of getting the claim wrong fails with a reason; a feature verified with no RED evidence is advised and never failed; a docs change is not; this repository's own record for this change carries a real RED commit; and every line carries its outcome as a word.

## Personas
- A developer who wrote the failing test, committed it, then made it pass (EVAL-001).
- The same developer naming the wrong commit three different ways (EVAL-002), and one who committed a test with nothing after it (EVAL-003).
- A developer who verified a feature with tests written after the fact, then a docs-only change (EVAL-004).
- The maintainer reading this change's own history (EVAL-005).
- A screen-reader user, or a CI log reader (EVAL-006).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-006, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log`; RED and GREEN commits are made by hand in the scratch repository and their hashes fed into `tests.yml`.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied. Screen-reader readability is exercised in EVAL-006: the skipped check, the advisory, and a failing check are piped through a filter that deletes every non-ASCII byte and still read `skip red evidence:`, `warn verification:`, and `fail red evidence:` with the full reason.
