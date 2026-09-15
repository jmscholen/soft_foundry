# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against real scratch repositories carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process (not a StringIO): a change in a governed application is checked against what that application has published in its own privacy and security policies; the gaps are *reported* on the output of `onboard`, `change new`, `gate`, `change status`, and `check`; an owed policy text change is routed to a human decision; and none of it blocks anything.

## Personas
- A developer in a Rails application that publishes `PRIVACY.md` and `.github/SECURITY.md`, opening a change that sends page views to an analytics vendor (EVAL-001 to EVAL-005).
- The product owner who must decide whether the privacy policy may name that vendor (EVAL-004).
- A maintainer of a library-shaped repository (this one) whose profile records honest absence of policies (EVAL-006).
- An operator of an installed control plane that has lost the standard file (EVAL-007).
- A screen-reader user, or a CI log reader, consuming the same output with every non-ASCII character stripped (EVAL-008).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-008, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log` of every command and its exit code.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied (no prompts anywhere; every journey completed without input). Screen-reader readability is exercised directly in EVAL-008: `gate` output is piped through a filter that deletes every non-ASCII byte, and the assertion is that each policy advisory still reads `warn policy:` followed by what to do. The same run confirms zero escape sequences.
