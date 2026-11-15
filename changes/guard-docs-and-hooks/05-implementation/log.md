# Implementation Log

## Changes made
No application, test, or infrastructure code changes in this phase (REQ-GDH-005).

The three files no skill may write were applied by the maintainer commit `b9f4d7c`, before this record existed:

| File | Requirement | Change |
| --- | --- | --- |
| `.claude/settings.json` | REQ-GDH-001 | `soft-foundry hooks install --claude`: the PreToolUse matcher gains `Grep` and `Glob`; a PostToolUse entry (matcher `Bash`) runs `soft-foundry guard --after`. |
| `.codex/hooks.json` | REQ-GDH-001 | `soft-foundry hooks install --codex`: rewritten to the current install; unchanged in content. |
| `.ai/policies/enforcement.yml` | REQ-GDH-002 | The header comment describes the checks per tool, how a shell command is read, the fail-closed rule, the guard's own configuration, the post-call restore, and what can still get past it. `guard.mode: block` is unchanged. |
| `.ai/harness-evals/README.md` | REQ-GDH-003 | A paragraph and the invocation for a live eval on Claude Code. |

`soft-foundry doctor` after the install: `pass guard hook (claude: installed, codex: installed; mode: block, repository policy)`. `soft-foundry check`: no errors.

`README.md` (REQ-GDH-004) is written in the documentation phase.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
The intake skill may not name `exe/` in a shell command, so `phase seal` was run through the gem built and installed from this checkout (`gem build soft_foundry.gemspec`, `gem install --local`), which is the README's install path and carries the same code as `main`.
