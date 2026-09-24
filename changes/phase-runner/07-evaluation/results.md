# Evaluation Results

Commit SHA: 9f855b51a833b6fb43ca9b30ca8314a9550f7c5d

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-RUN-001, REQ-RUN-005, REQ-RUN-006 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-RUN-002 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-RUN-001, REQ-RUN-003, REQ-RUN-004, REQ-RUN-007 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-RUN-003, REQ-RUN-004 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-RUN-007 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-RUN-006, REQ-RUN-007 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- The four non-zero exits are the three refusals in EVAL-002 (exit 1 each) and the failed session in EVAL-004 (exit 1), each the journey's intended outcome. The exploring refusal in EVAL-002 shows exit 0 because the restoring `git checkout` is last in its chain; the refusal line two lines above is the result.
- The fake `claude` prints `fake claude: args before prompt: -p`, confirming the prompt was the last argument and `-p` the only one, and `working 13-review of changes/c1`, confirming it found the phase in the prompt the way an agent would.
- EVAL-003's gate shows `evidence current: no code changes since <sha>` because the fake shell bound the handoff to the scratch repository's HEAD; it is that repository's evidence, not this one's.
- A first transcript for this change was generated against a commit that had not landed (the pre-commit hook had rejected it); it was deleted and this one generated at commit 9f855b5.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts; the fresh session inherits the terminal and the runner waits for it.
- Screen-reader readability (EVAL-006): with every non-ASCII byte deleted, the advisory reads `warn review:` followed by the complete sentence, and the dry run reads `warn guard:` and `would run judge of c1 with: claude -p <prompt>`. Escape sequences: none observed.
- Line orientation: the runner's progress is one line per event (guard warning, billing, running, shell exited, then the gate's lines), so a reader can tell where a run stopped.
- Plain language: refusals say which phase, why, and what to do (`run change vet first`, `the gate will say when it is stale`).
- Residual: the fresh-context advisory is about 170 characters on one line; same shape as earlier long-line findings.

## Scope note
Performed directly by the interactive session against real scratch repositories carrying this repository's actual `.ai/` control plane, the real CLI executable as a separate process under Ruby 3.3.1, and fake `claude`/`codex` executables on PATH, with every provider key unset.
