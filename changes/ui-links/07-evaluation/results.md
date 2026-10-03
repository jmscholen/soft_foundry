# Evaluation Results

Commit SHA: 3562625d953805f7ee47a9a0a3fc032d146ea22d

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-LINK-001 | pass | evidence/browser-observations.log |
| EVAL-002 | REQ-LINK-002, REQ-LINK-003 | pass | evidence/browser-observations.log |
| EVAL-003 | REQ-LINK-004 | pass | evidence/browser-observations.log |

## Failures
None at the verified commit. One found and fixed during the pass: the board's column headers had links without popups.

Observations:
- EVAL-NOTE-001: a gate referenced from another change (a repository card, Running) has a popup with its path but not its state, because only the change on screen is loaded. Opening the change shows the state.
- EVAL-NOTE-002: a board with two tables now has 32 header links before its rows; a keyboard user tabs through them.
- EVAL-NOTE-003: popups were opened by dispatching the events a pointer and keyboard cause, not by a pointer; the pointer-over-popup hold was not driven.
- EVAL-NOTE-004: no screen reader, light scheme, or zoom, as before.

## Accessibility observations
Each popup is the one `role="tooltip"` element, named by `aria-describedby` on the reference while shown, opened by focus as well as hover, and closed by Escape, blur, and navigation. Links are underlined; a commit reference that is not a link is dotted-underlined and focusable.
