# Security Review

## Scope reviewed
What the gate reads (`tests.yml`, git objects by hash and path) and what it does with the values (hashes validated against `/\A[0-9a-f]{7,40}\z/` before reaching git; `test_path` passed to `cat-file` as `sha:path`, a single argument through `Open3` with no shell).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-010 | info | `lib/soft_foundry/gate.rb` | `red_commit` is matched against `SHA` before any git call; a non-hash value is reported, never passed on. `test_path` reaches `git cat-file -e` as one argument; a path with `..` or a leading `/` simply does not exist in the tree and fails the check. | `.ai/rules/security.md` |
| REV-011 | info | trust model | A `red_commit` is a claim the gate shapes but does not prove. An agent could commit a trivially failing test, then an implementation, and name them; content is the review's job, and a person can check out the RED commit. Same trust level as every other field in the record. | `.ai/policies/human-boundaries.yml` |
| REV-012 | info | `evidence/red-at-5d898e0.log` | Produced by checking out the RED commit in this worktree with a stash around it; the log names the commit and the command. No history was rewritten. | `.ai/rules/git.md` |

## Conformance
Conforms.
