# Evaluation Plan

Commit evaluated: `2af76ba9b26be41af5bcafa12ee56eda635f6c77` (HEAD of `change/guard-docs-and-hooks`; the implementation is the maintainer commit `b9f4d7c`, unchanged since).
Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`; no scope declared, so the whole repository is sized at the largest size: every route, plus the journeys the change touches).

## Intent being proven
Two conditions of approval from factory-readiness are discharged on this branch: this repository's own guard hook is the current install (the PreToolUse matcher covers Grep and Glob, a PostToolUse entry runs `guard --after`), and the guard is described where people read about it as it behaves on `main` at 0.23.0. The requirements are REQ-GDH-001..005 in `00-intake/request.md`; the specify phase is waived, so no acceptance criterion exists (AC-001 in `02-specification/` is the unfilled template and is named by no journey).

The feature has no UI. The people who perceive or operate it are: a coding agent whose tool calls the hook checks, a maintainer running `soft-foundry` commands, and a reader of the policy header and the README. Every journey is one of theirs, run for real against this checkout's library (`ruby -I<repo>/lib <repo>/exe/soft-foundry`), either in this session (the committed hook is in effect here) or in a scratch repository under the system temp directory whose guard configuration is the subject under test. Nothing in this repository outside `07-evaluation/` is written, and this repository's own guard configuration is never named in a shell command.

## Personas
- **Agent session**: a Claude Code session on this branch with the evaluation skill active, whose Bash, Read, Grep, Glob, Write and Edit calls the committed hook decides.
- **Maintainer**: runs `hooks install`, `doctor`, `check`, `eval`, `ci` and every other route; reruns `hooks install --claude` on a repository that still has the old matcher; overrides the mode on their own machine.
- **Reader**: reads the header of `.ai/policies/enforcement.yml` and the README guard section and checks each claim against a command's output.

## Journeys
Recorded in `journeys.yml`; outcomes in `results.md`.

| ID | Requirement | Persona | What is exercised |
| --- | --- | --- | --- |
| EVAL-001 | REQ-GDH-001, 002 | Agent session | The committed hook refusing and allowing this session's own calls: Bash naming the guard's configuration or protected policy, Grep and Glob into `.ai/harness-evals`, Write outside the repository, Write into a deny_write phase; Read of the configuration allowed |
| EVAL-002 | REQ-GDH-001 | Maintainer | `doctor` on this checkout; a fresh `hooks install` compared with the committed `.claude/settings.json` and `.codex/hooks.json` |
| EVAL-003 | REQ-GDH-001 | Maintainer | Rerunning `hooks install --claude` on a repository with the pre-`b9f4d7c` settings (old matcher, no PostToolUse, an unrelated hook and key); idempotence; `--codex`, `--local`, `uninstall`; `doctor` before and after |
| EVAL-004 | REQ-GDH-002 | Reader | Every checkable claim in the policy header fed to `soft-foundry guard` as a hook payload in a scratch repository: the per-tool checks, Grep and Glob prefixes, symlinks, how a shell command is read (segments, cd, pushd, globs, braces, absolute paths), what is refused and what may be named, undecidable calls, the guard's own configuration, the pre-call baseline and post-call restore, the modes and their precedence, unguarded states, Codex and Grok tool names |
| EVAL-005 | REQ-GDH-002 | Maintainer | Turning the guard `off` in the policy or the override file as the header spells it |
| EVAL-006 | REQ-GDH-003 | Reader | `.ai/harness-evals/README.md`: blocked, this skill is denied it |
| EVAL-007 | REQ-GDH-004 | Reader | README.md as it stands at this commit: what the owed text would have to add; the documentation phase has not run yet |
| EVAL-008 | REQ-GDH-005 | Maintainer | Every CLI route from this checkout's library in a scratch repository (the full route sweep); `check`, `eval`, `ci` on this checkout; the diff from `main` |
| EVAL-009 | accessibility | Maintainer, agent | The CLI output rules of `.ai/rules/accessibility.md` on `doctor`, the hook's refusals, `hooks install`, and the sweep's 62 routes with stdin closed |

## UI walkthrough evidence
No UI exists. The equivalent is transcript evidence under `evidence/`: the hook's verbatim replies in this session (`guard-live.txt`), the scripts under `evidence/scripts/` and their outputs, each listed with a digest in `evidence/manifest.yml`.

## Accessibility interaction
`surfaces.accessibility` is true: a person reads the policy header and the README, and reads CLI output. The CLI and log output rules apply (outcome words, no ANSI when piped, line-oriented with stable prefixes, no interactive prompts, errors that say what to do next); the document rules apply to the README text the documentation phase will write, which is not yet there. Keyboard-only operation, focus order and screen-reader names apply to interactive controls, of which there are none: every decision is a flag, and the sweep drives every route with stdin closed; what a screen reader gets is the outcome word on every line. Recorded under "Accessibility observations" in `results.md`.
