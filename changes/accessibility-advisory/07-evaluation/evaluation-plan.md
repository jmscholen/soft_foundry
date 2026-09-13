# Evaluation Plan

## Intent being proven
The maintainer's instruction, end to end, against a real scratch repository carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process (not a StringIO): accessibility and review gaps are *reported* on the output of `gate`, `change status`, `ci`, and `change close`, in a form a screen reader or a CI log can read, and never block anything.

## Personas
- A developer in a Rails application repository opening a change that touches a checkout form (EVAL-001 to EVAL-003).
- A maintainer of a library-shaped repository (this one) opening a small change and waiving review and judgment with a rationale (EVAL-004, EVAL-005).
- A screen-reader user, or a CI log reader, consuming the same output with every non-ASCII character stripped (EVAL-006).
- An operator of an installed control plane that has lost the standard file (EVAL-007).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-007, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log` of every command and its exit code.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied (no prompts anywhere; every journey completed without input). Screen-reader readability is exercised directly in EVAL-006: `doctor`, `check`, and `gate` output is piped through a filter that deletes every non-ASCII byte, and the assertion is that every outcome is still identifiable by its word. The same run confirms zero escape sequences and zero non-ASCII characters beyond the four decorative glyphs across `doctor`, `check`, `gate`, `change status`, and `ci`.
