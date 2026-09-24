# Evaluation Results

Commit SHA: a5648d0b5b6933a361a34d30daf9fb77cb740014

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-LRN-001, REQ-LRN-002 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-LRN-003 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-LRN-005 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-LRN-004, REQ-LRN-005, REQ-LRN-006 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-LRN-007 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-LRN-004, REQ-LRN-005 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- The one exit 2 is EVAL-001's malformed-instincts gate, the journey's intended outcome; EVAL-003's refusal exits 1 and prints `promote-exit=1`.
- A first transcript was discarded: the script branched the promoting change from `main`, which held no records, so `promote` found nothing and printed nothing. That was the script; the corrected run branches from `change/c2`. The same run showed `learn list` printing "when when", which was a real output defect fixed in `a5648d0` before this transcript was regenerated.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts.
- Screen-reader readability (EVAL-006): with every non-ASCII byte deleted, the lines read `skip <id>: already in .ai/rules/learned.md`, `skip <id>: confidence 0.60 is below 0.80`, and `fail learn promote: no change record for branch 'main' ...`. Escape sequences: none observed.
- Line orientation: one line per instinct in `list` and `promote`, each starting with its outcome or its confidence, so a reader can stop at any line.
- Plain language: every skip says why; the refusal says what a promotion is and where it goes.
- Residual: a `learn list` line carries the whole trigger and action and can run past 200 characters; a `--short` form would help a screen reader. Noted for the review.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process under Ruby 3.3.1, with every provider key unset.
