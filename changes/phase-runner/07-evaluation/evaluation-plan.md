# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against real scratch repositories carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process, with a fake `claude` and `codex` on PATH that behave like an agent (complete the phase named in the prompt, or fail on request): a phase runs in a new session with only its skill in the prompt; the runner refuses what the gate would refuse; a completed run is stamped and gated; a failed run leaves the attempt; a review completed by hand is advised; and the lines carry their outcome as words.

## Personas
- A maintainer with a change through evaluation asking for the review to run fresh, first as a dry run (EVAL-001).
- A maintainer asking for phases the gate would refuse (EVAL-002).
- The fresh session itself, completing review; then failing on judgment (EVAL-003, EVAL-004).
- A maintainer who completed a review in the implementing session (EVAL-005).
- A screen-reader user, or a CI log reader (EVAL-006).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-006, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log`. The fake shells are two-line scripts that print the arguments they received before the prompt, extract the phase directory from the prompt, and complete it with the same helper the tests use; `FAKE_EXIT=3` makes them fail without writing.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied. Screen-reader readability is exercised in EVAL-006: the fresh-context advisory and the runner's dry-run lines are piped through a filter that deletes every non-ASCII byte, and the assertion is that they still read `warn review:` and `warn guard:` followed by the full message.
