# Evaluation Results

Commit SHA: 0d3a0436374b6af728209f039ed577a40c960d3a

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-PS-001, REQ-PS-003, REQ-PS-004, REQ-PS-005 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-PS-001 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-PS-001, REQ-PS-002 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-PS-004 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-PS-008 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-PS-007, REQ-PS-008 | pass | evidence/browser-observations.log |
| EVAL-007 | REQ-PS-007 | pass | evidence/browser-observations.log |
| EVAL-008 | REQ-PS-007 | pass | evidence/browser-observations.log |

## Failures
None. Observations:

- EVAL-NOTE-001: the sessions were real runners with stand-in shells. A real Claude or Codex session was not started for this evaluation; a real one in another project was listed correctly by an earlier run of `ps`-style inspection during the previous change, by the same recognition rule.
- EVAL-NOTE-002: a spoofed process appears as "phase run" with the default shell and nothing else. It is harmless and it is a row that is not a real session.
- EVAL-NOTE-003: a session that ends between two polls is simply gone from the list; nothing says it finished. The change's gate then says what the phase's handoff says.
- EVAL-NOTE-004: macOS only. Linux is exercised by CI's run of the real-process test, not by these journeys.
- EVAL-NOTE-005: no screen reader, light scheme, or zoom, as in the earlier changes.

## Accessibility observations
The Running table has a caption and scoped headers and scrolls inside its own focusable region at 614 px. Running and interrupted are stated in words on the board, in the change, and in the terminal. The unexercised items in EVAL-NOTE-005 remain owed.
