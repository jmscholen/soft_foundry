# Evaluation Plan

## Intent being proven
A person can install the session hook without disturbing their own agent configuration, every Claude Code and Grok session is then recorded as it happens with its repository, change, and phase, and the person (or an agent using the find-session skill) can find it again by words and get a command that really resumes it. Grok is recorded as Grok even though it also runs Claude's hooks.

## Personas
- The maintainer, at a terminal, with several coding shells across repositories (the person who will install this).
- A coding agent asked in plain English to find an earlier session (the find-session skill's user).

## Journeys
See `journeys.yml` (EVAL-001 to EVAL-007). All run by `evidence/journey-transcript.log`'s script against a throwaway repository carrying this repository's real `.ai/` control plane, the real CLI executable as a separate process (through a `soft-foundry` shim on `PATH` pointing at this checkout), live Claude Code and Grok sessions, and a temporary home directory for installs, so the maintainer's real configuration is never touched. The live sessions use project-level copies of exactly the entries the user-level install wrote, because the agents read user-level configuration from the real home.

## UI walkthrough evidence
EVAL-005 reads the change's data from the running UI server with its token; the rendered "Recorded sessions" section is checked in a browser and recorded in `results.md`.

## Accessibility interaction
`surfaces.accessibility` is true. CLI: every new line's status word, output with non-ASCII bytes deleted and `NO_COLOR` set, no escape sequences, no prompts (EVAL-007). UI: the section is a heading plus a list with status in text and commands as selectable text; keyboard and screen-reader structure are checked in the browser (EVAL-005).
