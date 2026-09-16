# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against real scratch repositories carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process (not a StringIO): a feature can be shaped with a person on the iterative track without the hardening ceremony, the person's acceptance is a recorded command that locks the specification, the hardening phases then apply exactly as on the gated track, a change can be sent back to exploring, a high risk change cannot take the lighter path, the gated track and the control-plane lint behave as before plus the new invariant, and every new line is readable without its glyph.

## Personas
- A developer on a feature the product owner wants to try before it is specified, opening a change on the iterative track, journalling rounds, and asking for the vet (EVAL-001 to EVAL-006).
- The product owner who accepts the feature with `change vet`, later wants a different shape, and sends it back with `change reopen` (EVAL-003, EVAL-006).
- A developer who declared the change high risk (EVAL-007).
- A developer on the gated track who expects nothing to have changed (EVAL-008).
- A control-plane maintainer editing the tracks block or the stage skill's permissions (EVAL-009).
- A maintainer of a repository whose profile records no development environment (EVAL-010).
- A screen-reader user, or a CI log reader, consuming the same output with every non-ASCII byte stripped (EVAL-011).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-011, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log` of every command and its exit code, produced by a script that runs the real executable under Ruby 3.3.1 from inside each scratch repository with `pipefail` on, so a pipeline's exit is the gate's exit when the gate fails.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied (no prompts anywhere; every journey completed without input). Screen-reader readability is exercised directly in EVAL-011: `gate verify` and `change status` output is piped through a filter that deletes every non-ASCII byte, and the assertion is that the new `fail not exploring` and `fail predecessor complete` lines and the track line still carry their meaning as words. Escape sequences are counted and expected to be zero.
