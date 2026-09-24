# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against a real scratch repository carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process: a clean plane passes; an injected rule, policy, or pointer file is found at the right level; the marker and the allowlist exempt what they should and `check` refuses an unreasoned entry; the gate fails a phase with a secret or invisible text and warns on a quoted attack; `scan` runs on demand over everything or one path; this repository's own scan and promoted rules are clean; and every line carries its outcome as a word.

## Personas
- A maintainer with a clean control plane (EVAL-001).
- An attacker's pull request editing a rule, a policy, and `AGENTS.md` (EVAL-002).
- A rule author quoting an attack, and a maintainer writing an allowlist entry without a reason (EVAL-003).
- An agent whose evidence holds a canary key, a quoted attack, and an invisible character (EVAL-004).
- A maintainer running `scan` on demand (EVAL-005); this repository itself (EVAL-006).
- A screen-reader user, or a CI log reader (EVAL-007).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-007, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log`, with one deliberate rendering: the harness writes invisible characters as their code points (`<U+200B>`) and masks key-shaped strings (`sk-canary[masked]`) before output reaches the file, so the evidence describes the attacks without containing them.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied. Screen-reader readability is exercised in EVAL-007: `scan` and gate output are piped through a filter that deletes every non-ASCII byte and still read `error <path>:<line> <kind>: <detail>`, `warning ...`, `fail scan: ...`, and `fail content clean: ...`.
