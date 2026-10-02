# Evaluation Results

Commit SHA: 5d36e6f80e14c07928d3b5f1490403b17e01982e

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-UI-001, REQ-UI-002, REQ-UI-004 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-UI-001 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-UI-004, REQ-UI-007 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-UI-005 | pass | evidence/browser-observations.log |
| EVAL-005 | REQ-UI-006, REQ-UI-007 | pass | evidence/browser-observations.log |
| EVAL-006 | REQ-UI-008 | pass | evidence/browser-observations.log |
| EVAL-007 | REQ-UI-001 | pass | evidence/journey-transcript.log |

## Failures
None at the verified commit. Found and fixed during evaluation, before GREEN: the page was refused when opened from a link (see `05-implementation/deviations.md`); column numbers on the board were misaligned; standalone links were 18 px tall.

Limits of this evaluation:
- EVAL-NOTE-001: no screen reader was run. Structure, names, and the live region were inspected in the DOM, which is necessary and not sufficient.
- EVAL-NOTE-002: the light colour scheme was not viewed, only its contrast computed. 200% zoom and a real 320 px viewport were not exercised; reflow was checked by constraining the body.
- EVAL-NOTE-003: Ctrl-C was exercised as SIGINT sent to a directly started server (exit 0, "ui: stopped"), and SIGTERM in the transcript; not as a key press in a terminal.
- EVAL-NOTE-004: only Chrome was used.

## Accessibility observations
Keyboard operation, focus visibility and retention, structure, state words, contrast, reflow, target size, pause, and reduced motion were each checked and conform (details in the log). The unexercised items above are owed before this is called conformant by a person who relies on them.
