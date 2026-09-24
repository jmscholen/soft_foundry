# Evaluation Results

Commit SHA: 7306119ba99bd292ef70dd509fd68697a651b81c

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-RG-001, REQ-RG-002, REQ-RG-007 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-RG-002 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-RG-002 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-RG-004 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-RG-007 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-RG-002, REQ-RG-004 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- Every exit 2 in the transcript is a `gate verify` the journey set out to fail (EVAL-002, EVAL-003, and the stripped repeat in EVAL-006), carried through the pipeline by `pipefail`.
- A first transcript was discarded: the script's `printf %s` wrote a literal `\n` into `tests.yml`, so every RED step reported `tests.yml is not valid YAML` instead of the claim under test. The script was corrected (`%b`) and rerun in full. The invalid-YAML path it exercised by accident behaves as designed and is covered by a test.
- EVAL-005 runs in this repository, not a scratch one; it reads history only.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts.
- Screen-reader readability (EVAL-006): with every non-ASCII byte deleted, the lines read `skip red evidence: no check records a red_commit`, `warn verification: no check in 06-verification/tests.yml records a red_commit, ...`, and `fail red evidence: CHECK-001: no APP or INFRA change between ...`. Escape sequences: none observed.
- Line orientation: one `red evidence` line per gate run, listing each check by id with its two short hashes, so a reader hears the trail in order.
- Plain language: every failure names the check id, the offending hash, and what is wrong with it ("is the verified commit itself", "is not an ancestor", "does not exist at", "nothing was implemented after the test").
- Residual: the advisory line is about 180 characters; same shape as earlier long-line findings.

## Scope note
Performed directly by the interactive session against real scratch repositories carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process under Ruby 3.3.1, with every provider key unset.
