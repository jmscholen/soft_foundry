# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Name the forgeable signal | `.ai/skills/remediation/SKILL.md` | ATK-001, ATK-010, ATK-014 | When a remediation adds or changes a check, state in the summary which signal the check reads and what a committer's hand edit of that signal does; add a case for it. |
| Measure git cost with the change | `.ai/skills/implementation/SKILL.md` | EVAL-017 | When a change adds a check that calls git, record the git call count and wall time of `gate all` before and after in the implementation notes. |
| Evidence phases run one at a time per worktree | `.ai/README.md` | exit 137 on parallel evaluate and attack, VER-003 | Run `phase run` for evidence phases serially unless the repository's suite is known to isolate its temp directories and processes. |
| Refusals end with an action | `.ai/rules/learned.md` (through `learn promote`) | EVAL-018 | Every gate or command refusal names the file or state at fault and the command that fixes it. |
