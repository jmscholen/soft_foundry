# Evaluation Plan

## Intent being proven
A person or a program can get the state the CLI prints as data, for this repository's real records, and nothing about the existing text output moved.

## Personas
- The maintainer of this repository, with twenty real records (eighteen closed).
- A program consuming the JSON (the browser page in the next change; a CI step).
- A reader of CI logs or a screen-reader user reading the help text.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`; transcript in `evidence/journey-transcript.log`.

- EVAL-001 the board for this repository (REQ-SNAP-003, REQ-SNAP-006).
- EVAL-002 one open and one closed change in full (REQ-SNAP-004, REQ-SNAP-005, REQ-SNAP-006).
- EVAL-003 failing gate, unknown slug, and unreadable record in a scratch repository (REQ-SNAP-003, REQ-SNAP-007).
- EVAL-004 text output of five commands compared byte for byte with `main` (REQ-SNAP-001).
- EVAL-005 the new help lines with non-ASCII bytes stripped (REQ-SNAP-007).

## UI walkthrough evidence
No UI exists in this change. The transcript is the equivalent evidence.

## Accessibility interaction
`surfaces.accessibility` is true because the change adds command-line output: two help entries and JSON. Exercised: the help lines read complete with non-ASCII bytes stripped (EVAL-005); JSON output is uncoloured, has no decoration, and states each outcome as a word (`"state": "fail"`, `"outcome": "pass"`); errors go to stderr as one plain line (EVAL-003). Keyboard operation, focus, and screen-reader names apply to the page in the next change, not here.
