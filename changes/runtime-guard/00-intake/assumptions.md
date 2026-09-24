# Assumptions

## Explicit assumptions
- A Claude Code PreToolUse hook receives a JSON object on stdin with `tool_name` and `tool_input` (`file_path` for Edit, Write, Read, MultiEdit; `notebook_path` for NotebookEdit; `command` for Bash), and refuses the call by exiting 2 with the reason on stderr. This is the documented contract and the one ECC's hooks use.
- "The active skill" is a fact the change record already states: `status: exploring` selects the track's stage skill, otherwise `current_phase` selects the phase skill. The guard reads those; it does not guess from the files being touched.
- Warn is the right shipped default. The guard is new, its Bash heuristic is a heuristic, and a wrongly blocked call in a governed repository is worse on day one than a logged one. Block is one line in policy or one environment variable away.
- Read allow-lists are not enforced because they are written as context (what the skill should look at), not as a boundary; every skill's real read boundary is its deny_read set (harness evals, another phase's raw evidence).
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review phase is run for it because the change alters what an agent may do. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether the shared or the local settings file is the default target: shared (`.claude/settings.json`), because enforcement is a repository decision and the hook command has a fallback for machines without the gem on PATH; `--local` exists for a machine that wants the hook without committing it.
- Whether to fail open or closed on an unreadable payload: closed in block mode, because a guard that can be defeated by malformed input is not a guard; open with a warning in warn mode, because warn mode promised not to block.
- Whether a Bash command that names a denied path should be refused even when it only reads it (`cat .ai/policies/budget.yml`): yes, when the path is in deny_read or deny_write. The guard cannot distinguish reading from writing in a shell command, the deny sets are small, and the agent can use the Read tool for a permitted read.
- Whether the guard should apply on `main` with no change record: no. Governance attaches to a change; work outside one is the maintainer's own, as `AGENTS.md` already assumes.
- Whether `governance.skill_permissions` can be PASS when a machine may not have the hook installed: yes. The capability is that the repository declares, lints, and can enforce; whether this machine installed the hook is what `doctor` is for. The maturity rule says exactly this.

## Ambiguities that block safe progress
None.
