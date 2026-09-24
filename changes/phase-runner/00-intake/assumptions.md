# Assumptions

## Explicit assumptions
- `claude -p <prompt>` and `codex exec <prompt>` are the non-interactive entry points of those shells and take the prompt as their last argument; extra arguments (a model, a permission mode) go before it. The runner does not try to know each shell's options.
- A fresh session that reads `AGENTS.md`, `.ai/README.md`, and one skill's five contract files has what a phase needs; the prompt therefore points at those files rather than restating them, so the record and the control plane stay canonical.
- `executed_by` is metadata about how a phase ran, not evidence the phase produced, so the runner may write it the way `change vet` writes `vetted`; the prompt tells the session to leave it alone and the advisory reads only the `fresh_context` flag.
- Separation of duties is about who looked at the work, so the advisory covers review and judgment only. Implementation being run in a fresh session is fine but is not what the capability is about.
- Evidence describes a commit on a branch. When a later branch builds on that commit, the later branch's own record covers its code; measuring the earlier record against the later branch's tip would make every stacked change fail `ci` for reasons that have nothing to do with the earlier claim. The merged-but-not-closed check, unchanged, still forces closure once the branch reaches the default branch.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review phase is run for it because the change alters what the lifecycle means by review. That choice is recorded here rather than silently assumed. This is also the last change whose review has to say that: the next one can use `phase run review`.

## Ambiguities resolved
- Whether the runner should refuse to launch without the guard hook installed: no. It warns, because a repository that does not use Claude Code has no guard to install and the phase still has to run; the warning names what goes unchecked.
- Whether `phase run` should accept any phase or only review and judgment: any phase. The refusals are the same for all, the code has no special cases, and an implementing session in a fresh context is a legitimate use even if it is not what the capability is about.
- Whether a failed session (non-zero exit) should reset the handoff: no. The attempt, its start time, and its exit status are the record; a rerun overwrites `executed_by` and the gate decides the rest.
- Why `ci` failed on this branch before the staleness rule changed: the runtime-guard record (open, on `change/runtime-guard`) read as stale against this branch's code. The rule was changed here rather than worked around by rebinding the earlier record to this branch's commit, because rebinding would have claimed the earlier evidence covers code it never saw.
- Why the pre-commit hook rejected two commits: it preferred `soft-foundry` on PATH, an installed 0.3.0 without the new rule, over this checkout. In a checkout of Soft Foundry itself the checkout is the tool under development, so both hook commands now prefer it; every other repository still gets the gem.

## Ambiguities that block safe progress
None.
