# Evaluation Plan

## Intent being proven
The maintainer's request, end to end, against real scratch repositories carrying this repository's own `.ai/` control plane and the real CLI executable as a separate process: a coding shell's tool calls are checked at runtime against the active skill's declared permissions; the hook installs and uninstalls cleanly beside a repository's own hooks; warn mode reports and logs without blocking, block mode refuses with exit 2; the phase and the exploring stage select the skill; Bash is deny-only; the environment and the machine-local override win over policy; unreadable input fails closed in block mode; nothing is guarded outside a change; and every line carries its outcome as a word.

## Personas
- A repository owner installing the guard into a `.claude/settings.json` that already holds their own hook and permissions (EVAL-001).
- A maintainer working on `main` with no change record (EVAL-002).
- An implementing agent on a change branch in warn mode, then in block mode via the machine-local override (EVAL-003 to EVAL-005).
- A verifying agent tempted to repair the code under test (EVAL-006).
- An operator flipping the mode from the environment, and a broken hook payload (EVAL-007).
- An exploring agent on the iterative track (EVAL-008).
- A control-plane maintainer who mistypes the mode (EVAL-009).
- A screen-reader user, or a CI log reader, consuming the same output with every non-ASCII byte stripped (EVAL-010).

## Journeys
See `journeys.yml`: EVAL-001 to EVAL-010, each mapped to the requirement IDs in `00-intake/request.md`, with steps, assertions, and the shared transcript as evidence.

## UI walkthrough evidence
No graphical UI. The evidence is the verbatim transcript `evidence/journey-transcript.log` of every command and its exit code. Hook payloads are fed to `soft-foundry guard` on stdin in the exact JSON shape Claude Code sends (`session_id`, `hook_event_name`, `tool_name`, `tool_input`), with `pipefail` on so a pipeline's exit is the guard's exit.

## Accessibility interaction
Applicable: this change is CLI output and reviewer-facing documents, and `metadata.yml` declares `surfaces.accessibility: true`. Keyboard-only operation is trivially satisfied (no prompts anywhere). Screen-reader readability is exercised directly in EVAL-010: a refusal, a warning, and the doctor line are piped through a filter that deletes every non-ASCII byte, and the assertion is that each still reads `fail guard:`, `warn guard:`, or `pass claude guard hook` followed by the tool, the path, the skill, and the mode.
