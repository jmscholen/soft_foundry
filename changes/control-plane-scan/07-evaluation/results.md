# Evaluation Results

Commit SHA: 54ecc50a2f6410961901537cbcb8b89085085254

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-SCN-004, REQ-SCN-006 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-SCN-001, REQ-SCN-002, REQ-SCN-004 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-SCN-003 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-SCN-002, REQ-SCN-003, REQ-SCN-005 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-SCN-006 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-SCN-008 | pass | evidence/journey-transcript.log |
| EVAL-007 | REQ-SCN-004, REQ-SCN-006 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- Every exit 2 is a `check`, `gate`, or `scan` the journey set out to fail. Where a command is followed by a restoring `git checkout` in the same chain, the recorded exit is the checkout's and the tool's own exit is printed as `check-exit=`, `gate-exit=`, or `scan-exit=`.
- A first transcript was discarded. It contained the raw zero-width character and the raw canary key the journeys wrote, and the scan (correctly) flagged this record's own evidence. The harness now renders invisible characters as `<U+200B>` and masks key shapes as `[masked]` before output reaches the file; the transcript here is the corrected harness's complete run. Its three remaining warnings are the attacks the journeys quote.
- EVAL-006's repository-wide scan ran before this record's evaluation and review files existed; the summary line it captured reflects that moment. `06-verification/evidence/scan-against-self.log` is the scan at the verified commit with every file of this record present.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts.
- Screen-reader readability (EVAL-007): with every non-ASCII byte deleted, the lines read `error changes/c1/00-intake/assumptions.md:11 invisible: U+200B zero width space`, `warning ... override: ...`, `fail scan: 1 error, 1 warning in 259 files`, and `fail content clean: assumptions.md:11 invisible (U+200B zero width space)`. Escape sequences: none observed.
- Line orientation: one finding per line, path and line number first, kind next, detail last, so a reader can stop after the location.
- Plain language: an invisible character is named by code point and name; a secret by its shape, never its value; the detail says what to do (add the marker) where that is the answer.
- Residual: the override and fetch-and-execute detail repeats the marker hint on every line; a shorter form would help a screen reader on a long scan. Noted for the review.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process under Ruby 3.3.1, with every provider key unset.
