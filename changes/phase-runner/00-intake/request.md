# Change Intake

## User intent
Second of the five additions from the ECC evaluation, agreed with "ok, lets do the 5 recommended additions": fresh-context phase execution. Every record in this repository says "performed by the interactive session, not a fresh-context agent" in its handoff notes, and `governance.separation_of_duties` has been PARTIAL (`not_enforced_at_runtime`) since discovery. ECC runs its reviewer as a subagent with its own context. Soft Foundry's roadmap has a per-phase runner as a later item; the minimum version is a command that launches one phase in a new coding-shell session with only that phase's skill in its prompt, stamps the handoff with how it ran, and gates the result.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-RUN-001.** `soft-foundry phase run <phase> [--change SLUG] [--shell claude|codex] [-- args...]` launches a new non-interactive session (`claude -p <prompt>` or `codex exec <prompt>`, extra arguments inserted before the prompt) in the repository root with inherited stdio. The prompt names the change, the phase, the skill and its five contract files, what may be written, how to fill the handoff, and what not to do (edit `executed_by`, alter other phases' evidence, weaken requirements, run the runner recursively, pretend when blocked).
- **REQ-RUN-002.** The runner refuses, before launching, what the gate would refuse afterwards: an exploring change, a closed or judged change, a phase already complete, a phase whose effective predecessor is not complete, and an unknown phase. Refusals name the reason and exit 1.
- **REQ-RUN-003.** Before launching, the runner sets `current_phase` to the phase (so the guard applies that skill), moves a `pending` handoff to `in_progress`, and writes `executed_by` with `runner`, `shell`, `fresh_context: true`, `started_at`, and `previous_phase`. After the session it writes `finished_at` and `exit_status`. A session that dies still leaves the attempt in the record.
- **REQ-RUN-004.** When the session returns, the runner prints the shell's exit status, evaluates the phase's gate, prints the result and the advisories, and exits 1 if the shell failed, 2 if the gate fails, else 0.
- **REQ-RUN-005.** `--dry-run` prints the command (with the prompt elided) and the prompt itself, launches nothing, and stamps nothing.
- **REQ-RUN-006.** When the shell is `claude` and the guard hook is not installed, the runner prints a `! warn guard:` line naming the skill whose permissions will go unchecked and the install command, and continues.
- **REQ-RUN-007.** The handoff template carries `executed_by: null` with a comment that only the runner writes it. A completed review or judgment whose handoff lacks `executed_by.fresh_context: true` draws an advisory (`review` or `judgment` area) on every gate, status, ci, and close run saying it was completed without the runner and separation rests on the notes.
- **REQ-RUN-008.** Commit-bound evidence staleness is measured on the record's own `git.branch` tip (local, then `origin`) when that branch exists and is not the one checked out, and on the worktree (uncommitted edits included) otherwise, so a change stacked on another change's branch does not stale the earlier record while the merged-but-not-closed check still forces closure on the default branch.
- **REQ-RUN-009.** Both hook commands (pre-commit and guard) prefer a checkout's own `exe/soft-foundry` over a gem on PATH. The guard hook is installed in this repository's `.claude/settings.json`. This repository's profile records `governance.separation_of_duties: PASS` with the maturity rule that says when it is; `README.md`, `AGENTS.md` step 9, and `.ai/schemas.md` document the runner, `executed_by`, and the staleness rule. Version 0.11.0.
- **REQ-RUN-010.** Everything else is unchanged: all prior tests pass (three accessibility advisory tests now mark their review as runner-executed, since they test only accessibility notices), and `ci` against this repository's history passes on this stacked branch.

## Constraints
- The runner never writes phase content; the session does. The runner writes only `current_phase` and `executed_by`.
- The prompt is built from the record and the control plane; the only person-supplied text is what follows `--`, and that goes to the shell as arguments, never into the prompt.
- The runner must not spend a session on a phase the gate would refuse.
- Every new line carries its outcome as a word per `.ai/rules/accessibility.md`.

## Non-goals
- Worktree isolation per phase. The session runs in the current worktree; the roadmap's full runner may add worktrees.
- Model selection from the profile. `resolved_model` stays the session's to fill in; the runner passes extra arguments through for a person to choose.
- Orchestrating several phases in sequence. One phase, one session, one gate.
- Running the exploring stage. It is worked with the person by design.

## Task classification
Feature: a `PhaseRunner` module, a `phase run` CLI command, a handoff template field, an advisory, a gate staleness rule, a hook ordering fix, documentation, a profile and maturity update, tests.

## Initial risk
low. The runner spawns a shell the person already runs by hand, with a prompt derived from the record; its writes are two fields in the record. The staleness rule only loosens the measure for records on other existing branches, and the merged-but-not-closed check is untouched. Existing tests and change records pass unchanged.
