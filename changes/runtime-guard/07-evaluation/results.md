# Evaluation Results

Commit SHA: e5c48dcf9009b91a3032d77b15beb9f9fe6a9275

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-GRD-005, REQ-GRD-006 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-GRD-002 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-GRD-001, REQ-GRD-003 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-GRD-001, REQ-GRD-003 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-GRD-001 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-GRD-002 | pass | evidence/journey-transcript.log |
| EVAL-007 | REQ-GRD-003, REQ-GRD-004 | pass | evidence/journey-transcript.log |
| EVAL-008 | REQ-GRD-002 | pass | evidence/journey-transcript.log |
| EVAL-009 | REQ-GRD-007 | pass | evidence/journey-transcript.log |
| EVAL-010 | REQ-GRD-006, REQ-GRD-008 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- Each guard call prints its own exit as `guard-exit=N` before the shell's `[exit]` line, because the payload is fed through a shell function; the guard's exit is the number to read.
- `doctor` exits 2 throughout because the scratch repository has no manifest, pre-commit hook, or local runtime; the journey reads only its guard line.
- EVAL-009's recorded exit is 0 because the restoring `git checkout` is last in the chain; the `check` output two lines above shows the error and `✗ fail control plane: 1 error(s)`.
- EVAL-005's `cp lib/app.rb docs/copy.rb` is refused although `docs/copy.rb` does not exist: the heuristic treats any slash-containing token under the root as a path, which is the conservative direction for a deny check.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts; every journey completed without input.
- Screen-reader readability (EVAL-010): with every non-ASCII byte deleted, a refusal still reads `fail guard: Edit <path> is in <skill>'s deny_write set ... (mode: block, ...)`, a warning `warn guard: ...`, and the doctor line `pass claude guard hook (mode: warn, ...)`. Escape sequences: none observed in any guard output.
- Line orientation: one line per decision, one line per doctor check; the mode and its source are on the same line as the check they qualify, so a reader hears the state and the reason together.
- Plain language: every message names the tool, the path, the skill whose set applies, the file that sets the mode, and (in warn mode) where the violation was logged.
- Residual: the block-mode refusal runs to about 190 characters on one line. Same shape as the lifecycle-tracks review's REV-018; noted for the review.

## Scope note
Performed directly by the interactive session against real scratch repositories carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process under Ruby 3.3.1, with every provider key and `SOFT_FOUNDRY_GUARD` unset unless the step sets it.
