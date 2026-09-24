# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against a real scratch repository carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process: a change's learning phase writes instincts the gate validates; `learn list` shows them across records by confidence; `learn promote` refuses on `main`, and through a change record copies those above the threshold into `.ai/rules/learned.md` with provenance, idempotently, with a dry run that writes nothing and a threshold override; the promoted file is a baseline rule; and every line carries its outcome as a word.

## Personas
- A learning agent writing instincts, once well-formed and once not (EVAL-001).
- A maintainer surveying what the repository has learned (EVAL-002).
- A maintainer on `main` trying to promote without a record (EVAL-003), then doing it properly through a new change (EVAL-004).
- An implementing agent whose rules now include the promoted file (EVAL-005).
- A screen-reader user, or a CI log reader (EVAL-006).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-006, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log`; instincts are written by hand into two records and the promoting change is a third record on its own branch.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied. Screen-reader readability is exercised in EVAL-006: the promote output and the refusal are piped through a filter that deletes every non-ASCII byte and still read `skip <id>: ...` and `fail learn promote: ...` with the full reason.
