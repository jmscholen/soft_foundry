# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change. The gem packages the edited handoff template through the `.ai/**/*` glob; `test/installer_test.rb` still passes. The committed `.claude/settings.json` is a repository file Claude Code reads on this repository only. The GitHub Actions workflow is unchanged; its `fetch-depth: 0` checkout is what lets the branch-aware staleness rule find `origin/<branch>` tips in CI.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-020 | info | `.github/workflows/ci.yml`, `Git#branch_tip` | `actions/checkout` with `fetch-depth: 0` fetches every branch, so a PR run (detached HEAD) measures each open record against its own branch at `origin`. A workflow that changed to a shallow or single-ref fetch would make every other branch's record fall back to HEAD and read stale on stacked PRs; the workflow comment should say why the depth matters. Follow-up: one comment line. | `.ai/rules/infrastructure.md` |
| REV-021 | info | `.claude/settings.json` | Committed on purpose so every clone of this repository runs the guard in Claude Code; the command prefers the checkout's exe, so a clone without the gem still works. | `.ai/rules/infrastructure.md` |

## Conformance
N/A: no infrastructure is present or modified. Examined the CI checkout depth the staleness rule relies on.
