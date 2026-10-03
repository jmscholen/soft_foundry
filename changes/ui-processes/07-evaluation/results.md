# Evaluation Results

Commit SHA: dd18466001ecc7246f8266643a154bcdc1ff0ff5

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
| EVAL-009 | REQ-PS-009 | pass | evidence/journey-transcript.log, evidence/browser-observations.log |

## Failures
The first delivery failed its purpose: with five sessions open in the maintainer's terminals it listed none of them (see `09-remediation/summary.md`). The journeys below were run again after the fix and pass. Observations:

- EVAL-NOTE-006: the journeys in the first delivery all passed, because they staged the kind of process the implementation recognised. The evaluation tested what was built rather than what was asked for. EVAL-009 exists because the maintainer looked at their own screen.
- EVAL-NOTE-007: a session's phase is its change's `current_phase` as recorded. One real session's record showed status `intake` on a change long past intake in practice: the list is as current as the records are.

- EVAL-NOTE-001: phase runners were real, with stand-in shells. The hand-started sessions were of both kinds: stand-ins in the scratch repositories, and the maintainer's five real ones (four Claude Code, one Grok), which were listed correctly.
- EVAL-NOTE-002: a spoofed process appears as "phase run" with the default shell and nothing else. It is harmless and it is a row that is not a real session.
- EVAL-NOTE-003: a session that ends between two polls is simply gone from the list; nothing says it finished. The change's gate then says what the phase's handoff says.
- EVAL-NOTE-004: macOS only. Linux is exercised by CI's run of the real-process test, not by these journeys.
- EVAL-NOTE-005: no screen reader, light scheme, or zoom, as in the earlier changes.

## Accessibility observations
The Running table has a caption and scoped headers and scrolls inside its own focusable region at 614 px. Running and interrupted are stated in words on the board, in the change, and in the terminal. The unexercised items in EVAL-NOTE-005 remain owed.
