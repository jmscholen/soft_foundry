# Evaluation Results

Commit SHA: 05f44e9a6dd62a01ffc926e903aa8c6898f36ec2

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-POL-002, REQ-POL-003, REQ-POL-006 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-POL-003 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-POL-003, REQ-POL-004 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-POL-005, REQ-POL-006 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-POL-003 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-POL-002, REQ-POL-003, REQ-POL-007 | pass | evidence/journey-transcript.log |
| EVAL-007 | REQ-POL-001, REQ-POL-007, REQ-POL-008 | pass | evidence/journey-transcript.log |
| EVAL-008 | REQ-POL-006 | pass | evidence/journey-transcript.log |

## Failures
None at this commit. Two notes for the reader of the transcript:

- EVAL-004's final `gate review` exits 2. Rerunning the command shows the failed check is `predecessor complete: 08-attack is pending`: the journey marked the review complete without running the phases before it, and the gate correctly says so. Every other gate call in the transcript exits 0 while printing advisories, which is the property under test.
- The script's first two runs failed before any journey started because the scratch directory resolved to Ruby 2.7.8 through the version manager, and the CLI refused with its own version message. Pointing the script at the Ruby 3.3.1 binary fixed it; nothing in the change was involved.

## Accessibility observations
- Keyboard-only interaction: satisfied trivially. No command prompts; every journey, including `onboard` and `change status`, completed without input.
- Screen-reader readability (EVAL-008): with every non-ASCII byte deleted, the policy advisory line still reads `warn policy:` followed by the complete message naming what to confirm or change. Escape sequences: zero.
- Line orientation: every policy advisory is one line with the stable `! warn policy:` prefix, found with `grep` in every journey; `change status` carries `[status: awaiting_human]` in its first line so the parked state is visible without reading further.
- Plain language: each message names the file (`02-specification/requirements.yml`, `13-review/policy-conformance.md`, `.ai/repository.yml`, `metadata.yml`) and the action (add a requirement, set the flag, park the change, record the decision).
- Residual: the maturity summary printed by `onboard` still contains a decorative em dash, as recorded by the accessibility-advisory review's REV-012; unchanged by and outside this change.

## Scope note
Performed directly by the interactive session against real scratch repositories carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process, with every provider key unset.
