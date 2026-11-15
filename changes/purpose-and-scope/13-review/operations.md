# Operations Review

## Scope reviewed
What changes for someone running Soft Foundry once this merges, against `.ai/rules/observability.md` and the rollout facts in `00-intake/request.md`.

- **Runtime behavior.** None changes. No command, gate check, exit code or output line differs. `soft-foundry check` passes in the worktree (run by this session); the full suite and `ci` passed for the same tree outside `changes/` (`06-verification/evidence/`).
- **Effect on later changes.** From the merge on, every fresh attack session and review session in a repository that carries these skill files reads the new scope. Attack stops recording repository-write weaknesses as results; review grades them minor at most. That is the intended effect and it is not measured by this change (specification, "Performance and resource limits").
- **Reaching adopters.** The skill text ships in the control plane. A repository onboarded earlier keeps its old skill files until it updates them, so the two scopes will coexist for a time. Nothing in this change needed to address that.
- **Rollback.** Revert d944d07. No data, migration or state is involved.
- **Merge order.** The branch is stacked on `change/process-speed` (pull request 63) and merges after it.
- **Observability.** Nothing to detect: the change adds no failure mode at run time. A wrong edit to a skill file would be caught by `soft-foundry check` (structure and content scan), not its meaning.
- **State of the worktree.** Two guard configuration files were modified and uncommitted when this session started and were clean again by its end, without this session acting (REV-007). A person should look at the guard log to see what changed them and what put them back.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-007 | minor | worktree, not the commit | See security.md. Two guard configuration files differed from HEAD at the start of this session and were clean at its end, with no action by this session. Not caused by this change. | Guard configuration changes and reverts with no person acting, and a session runs under a weaker guard meanwhile. | `.ai/rules/security.md` |

## Conformance
Conforms. No operational behavior changes; one carried item for a person, not caused by the change.
