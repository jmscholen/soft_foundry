# Evaluation Results

Commit SHA: 2c74a369fe3ab24c4da40242dff5e6624f7fd8ef

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-A11Y-003, REQ-A11Y-005 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-A11Y-003, REQ-A11Y-005 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-A11Y-003 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-A11Y-003 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-A11Y-004, REQ-A11Y-005 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-A11Y-001 | pass | evidence/journey-transcript.log |
| EVAL-007 | REQ-A11Y-002, REQ-A11Y-006, REQ-A11Y-007 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. The first run of EVAL-007 failed on its scan step for a reason outside this change: the README documents `--maturity=scan` but the CLI's option parser accepts only `--maturity scan` (a separate argument), so the journey was corrected to the working spelling. Recorded for review as a pre-existing documentation defect (see 13-review/functional.md).

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts; every journey, including `change close`, completed without input.
- Screen-reader readability (EVAL-006): with every non-ASCII byte deleted, every `doctor` line still reads `pass` or `fail` plus the check name, `check` still reads `pass control plane`, and every `gate` line still reads `skip` or `pass` plus the check name. Advisory lines carry `! warn <area>:` in plain ASCII.
- Escape sequences: zero across `doctor`, `check`, `gate`, `change status`, and `ci`. Non-ASCII characters beyond the four decorative glyphs (`✓ ✗ — …`): zero.
- Line orientation: every advisory is one line with a stable `advisory:` heading and `! warn` prefix, searchable in a CI log (EVAL-005 found them with `grep` in `ci` output).
- Residual: the `—` and `…` characters remain in a few pre-existing lines (`ci`'s not-closed message and the maturity summary); both are decorative punctuation, and stripping them loses no meaning.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process, with every provider key unset.
