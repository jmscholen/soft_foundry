# Evaluation Results

Commit SHA: a7e9fd26063487f120cca2d762fa8eeb261f81b0

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-XCLI-003, REQ-XCLI-004 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-XCLI-001, REQ-XCLI-002 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-XCLI-005 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-XCLI-006, REQ-XCLI-007 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-XCLI-001, REQ-XCLI-005 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Notes for the reader of the transcript:

- `doctor` exits 2 throughout because the scratch repository has no manifest, pre-commit hook, or local runtime; the journeys read only its guard line. Each guard call prints its own exit as `guard-exit=N`.
- The transcript header records the installed `codex` and `grok` versions the contract was checked against. No live Codex or Grok session ran through the guard or the runner; the payloads follow Codex's documented shape.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts.
- Screen-reader readability (EVAL-005): with every non-ASCII byte deleted, the refusal reads `fail guard: apply_patch .ai/rules/injected.md is in implementation's deny_write set ...` and the warning `warn guard: grok has no hook mechanism, so the review skill's permissions are policy only for this session`. Escape sequences: none observed.
- Line orientation: one `guard hook` doctor line naming both hosts; one warning per launch; one refusal naming every offending path.
- Plain language: the install output says what Codex requires next (`/hooks`) in one sentence.
- Residual: the doctor line now runs to about 130 characters; still one line, still one status word.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process under Ruby 3.3.1, with every provider key unset unless the step sets `SOFT_FOUNDRY_GUARD`.
