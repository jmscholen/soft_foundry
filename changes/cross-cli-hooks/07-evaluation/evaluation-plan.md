# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against a real scratch repository carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process: the guard installs for Codex and `doctor` shows both hosts; the guard refuses the right paths when Codex sends an apply_patch (string or array, under its own name or the Edit alias) or an array shell command; the runner launches Grok headless and says its permissions are policy only, and names the Codex hook when that is missing; this repository has both hooks and the promoted rules; and every line carries its outcome as a word.

## Personas
- A repository owner installing for Codex, then Claude Code, then removing one (EVAL-001).
- A Codex session editing files and running commands under the implementation skill (EVAL-002).
- A maintainer running a phase under Grok and under Codex (EVAL-003).
- This repository (EVAL-004); a screen-reader user or CI log reader (EVAL-005).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-005, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log`; hook payloads are fed to `soft-foundry guard` on stdin in the shape Codex's documentation gives (`tool_name`, `tool_input.command` as string or array). The harness masks key-shaped strings before output reaches the file; none occurred.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied. Screen-reader readability is exercised in EVAL-005: a patch refusal and the Grok warning are piped through a filter that deletes every non-ASCII byte and still read `fail guard: apply_patch <path> ...` and `warn guard: grok has no hook mechanism ...`.
