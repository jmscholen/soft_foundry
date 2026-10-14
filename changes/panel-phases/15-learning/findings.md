# Learning

## What this change taught us
- **Same-user agents cannot be contained from inside the tool.** Four fresh-context Grok reviews each found deeper ways a member could act outside its stage: shell writes, then shell variables that hide paths, then writes anywhere in the repository, then detached processes, git hooks, ignored files, and copied-then-tweaked drafts. Each layer was closed (guard narrowing, runner fingerprints, repository-wide comparison) until the remaining holes needed an operating-system sandbox. The maintainer accepted that residual and the judgment recorded it.
- **The runner's own observations are the boundary; the guard is advice.** Parsing a shell command for paths is always evadable. Comparing what git sees before and after each stage held against every attack the reviews could run without leaving the repository's view.
- **Live runs found what tests could not.** Grok's `-p` argument order (change 1), Claude Code's working-folder limit (`--add-dir`), and hook-environment inheritance were all settled by running the real shells; the fixture-only tests had encoded the wrong assumptions twice.
- **A reviewer will always find something.** Change 2's rule held: every major finding named a concrete failure, which made each remediation testable. It also showed the cost: four review rounds for one feature. A threat model that names its trust boundary up front ("members are trusted-but-checked same-user sessions") would have ended the cycle earlier.

## Reviewer/evaluator/attack findings worth generalizing
- REV-SEC-001..015: state the trust model for agent sessions in the threat model before review, so review findings can be judged against it.
- REM-001..003: prefer one authoritative observation point (the repository snapshot) over many partial guards.

## Proposed deterministic checks
- The threat-modeling template could require a "trust boundary for agent sessions" line whenever a change launches coding shells.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
