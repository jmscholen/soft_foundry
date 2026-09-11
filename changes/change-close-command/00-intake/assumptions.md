# Assumptions

## Explicit assumptions
- "Merged" means the recorded commit is an ancestor of the repository's default branch (via `origin/HEAD`, falling back to a local `main`/`master`) — not "the branch still exists" or "a GitHub PR object says merged." This works whether or not the change went through an actual GitHub PR (soft_foundry's own changes always do; `my_ai`'s `bug-sweep-0910` was a local `git merge` with no PR at all).
- "Reached judgment" is the bar for treating a commit as meaningful for this check — not merely "the branch forked from a commit that's now old." An early phase's commit_sha is just wherever work started, and start points are always ancestors of a branch's own future. This was confirmed as a real defect (see 05-implementation/log.md) before shipping, not assumed correct in advance.
- The PR-comment confirmation format (`CONFIRMED: <id>[, <id>...]`) is deliberately simple text-matching, not tied to comment authorship (no attempt to distinguish "a human" from "a bot" by GitHub account type) — that distinction is left to the user's judgment about who has access to comment on the PR, not something this tool tries to infer.

## Ambiguities resolved
- Whether to build the GitHub-comment mechanism at all, versus just the `--confirm` flag: resolved to build both, per the user's explicit "yes, build on" after evaluating the design — the flag alone doesn't create an auditable trail the way a PR comment does.
- Whether `change close` should also validate gate/phase completeness before closing: resolved no — `close` only asks "is this merged, and is everything undischarged confirmed." Gate correctness is `soft-foundry gate`'s job, already run continuously via `ci` while the change is open; re-checking it at close time would duplicate that without adding anything.

## Ambiguities that block safe progress
None.
