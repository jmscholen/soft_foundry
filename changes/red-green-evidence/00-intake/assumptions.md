# Assumptions

## Explicit assumptions
- "The test failed at the RED commit" cannot be verified by the gate without checking out history and running a test runner the gate does not know; what can be verified is the shape: the commit exists, precedes the implementation, holds the test, and code changed after it. That is enough to make a false claim detectable by a person (check out `red_commit`, run the test) and expensive to fabricate by accident.
- "Code changed after the test" means an `APP` or `INFRA` path, not `TESTS`: a RED commit followed only by more tests or by docs is not GREEN.
- Features, fixes, and refactors are the change types that have something to fail first; docs, infrastructure, security, and chore changes may, but are not advised when they do not.
- The RED commit of this very change is real evidence only if the tests were committed before any implementation code. They were: `5d898e0` adds `test/red_green_test.rb` alone, and `evidence/red-at-5d898e0.log` is that file run with the worktree at that commit (nine runs, eight errors). Two helper-level fixes to the test file (the fixture had no `test/` directory; a hash literal passed as keywords) landed with the implementation; the expectations did not change.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review phase is run for it. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether `red_commit` should be required for features: no. Advised, per the maintainer's standing rule for this family of checks (report, never block advancement), and because a change may legitimately have been verified by characterisation tests written after the fact; the advisory makes that visible.
- Whether the gate should compare the test file's content between RED and GREEN: no. A test may be refined while going GREEN; requiring byte identity would punish that.
- Whether a RED commit on a different branch that was later merged should pass: yes, if it is an ancestor of the verified commit; `merge-base --is-ancestor` answers that regardless of branch.
- Whether invalid YAML in `tests.yml` should be a `red evidence` failure or a placeholder-style failure elsewhere: here, because this is the check that reads it as data; the `no placeholders` check reads it as text and cannot tell.

## Ambiguities that block safe progress
None.
