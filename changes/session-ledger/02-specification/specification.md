# Specification

## Intent
Never lose a coding session: every Claude Code, Codex, and Grok session on the machine is recorded as it happens with where it ran and what it was for, and can be found and resumed later from any folder, by words or by change and phase. Grok's tool calls get the same guard decisions as the other agents'.

## Personas and authorization boundaries
- **The maintainer** running several coding shells across several repositories. Owns the machine, the ledger, and every agent's configuration.
- **A coding agent** (Claude Code, Codex, Grok) whose hooks call Soft Foundry; it supplies hook payloads, which are untrusted input.
- **A find-session agent**: an agent asked "find the session where…", which runs the lookup command.
No new network surface, no other users. The ledger is readable only by the user who owns it.

## Functional behavior
- **Capture (REQ-SL-002, -003, -006).** The hook command reads one JSON payload from stdin, decides the agent (Grok by its camelCase key, otherwise the shell its hook entry names), derives repository root, branch, change, and phase from the payload's folder, and upserts the entry keyed by agent and session ID.
- **Lookup (REQ-SL-007).** `soft-foundry sessions` with words and filters; text output one session per block with a stable `session:` prefix line, or `--json`.
- **Resume (REQ-SL-008, -009).** `soft-foundry resume <change> [phase] [--agent]` prints one command.
- **Install (REQ-SL-010).** `soft-foundry hooks install --sessions` writes user-level hook entries and the find-session skill; `hooks uninstall --sessions` removes them.
- **Runner (REQ-SL-011)** and **UI (REQ-SL-012)** as stated in the requirements.

## Accessibility
REQ-SL-013. Command output follows `.ai/rules/accessibility.md` (status words, no color, line-oriented, stable prefixes, no prompts). The UI list follows WCAG 2.2 AA as applied there: a real list with a heading (1.3.1), text status (1.4.1), commands in selectable text with no pointer-only control (2.1.1), names exposed (4.1.2), reflow at 320 px (1.4.10).

## Data and consistency
The ledger is JSON Lines, one object per session. An update rewrites the file under an exclusive lock held from read to write. A line that does not parse is kept as is, never dropped. Fields: `agent`, `session_id`, `cwd`, `repo`, `branch`, `change`, `phase`, `transcript`, `first_at`, `last_at`, `first_prompt`, `latest_prompt`. Change and phase are those at the latest prompt.

## Failure behavior
REQ-SL-005: the hook command swallows every error, writes nothing, and exits 0. Lookup commands report a missing or unreadable ledger as "no sessions recorded" with how to install the hook, and exit 0 for an empty result, 1 only when `resume` finds nothing.

## Security requirements
REQ-SL-001 (guard mapping), REQ-SL-004 (masking, file modes, location), REQ-SL-009 (session-ID validation and shell quoting). The installer refuses symlinked targets and writes through `SafeWrite`, as the guard installer does.

## Privacy and security policy conformance
Soft Foundry publishes no privacy policy, security policy, or terms (`.ai/repository.yml`: all `NOT_APPLICABLE`), so no published clause is affected and `surfaces.policy` is false. What changes is what the tool keeps on the user's own disk once they install the hook: folders, branches, change names, and masked prompt excerpts, never transmitted. Discovery updated the profile's privacy rationale to say so, and README documents it (REQ-SL-015).

## Performance and resource limits
REQ-SL-014: under one second per recorded prompt with 5,000 entries. The ledger is not pruned in this change; growth is about 1 KB per session.

## Infrastructure implications
None. No deployed service.

## Observability expectations
None beyond the tool itself: the ledger is the record; `doctor` reports whether the hook is installed. A silent hook means faults are invisible by design; `sessions` showing nothing new is the signal, and README says to run `doctor`.

## Acceptance criteria
AC-001 to AC-015 in `acceptance-criteria.yml`.
