# Assumptions

## Explicit assumptions
- An instinct is the unit because it is what an agent can act on at the moment it matters: a trigger it recognises and one thing to do. A paragraph in `findings.md` is not.
- Confidence is the learning agent's honest estimate from one record, and promotion needs a threshold because a single record's lesson may be wrong. The threshold is policy, not code, so a repository can be stricter.
- The governance path is the point. `learn promote` refuses outside a change record so that a lesson reaches the rules the way every other rule change does: on a branch, through a record, at a merge a person decides. The change that learned the lesson cannot promote it into the rules it works under, because that change's record is where the lesson lives and promotion happens through a later one.
- Closed records still contribute instincts. A lesson outlives the change, and closing a record is about its evidence going stale, not its lessons.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review and learning phases are run for it. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether promotion should require the instinct's source record to be closed: no. A lesson from an open change is still a lesson; the threshold and the person running `promote` are the filters.
- Whether `learned.md` should be loaded by review too: no. Review checks work against the rules; loading learned rules into implementation and exploration is what makes them act; review reads the same file when it checks conformance, as it does every rule.
- Whether a promoted instinct's confidence should be updated when the same id appears again with a different score: no. The first promotion is recorded; a later change that wants to raise or lower it edits `learned.md` through its record.
- Why the tests were committed first and where the RED commit is: `a5c0d59` adds `test/learning_instincts_test.rb` alone (nine runs, all failing); the implementation is `55bce29` and one output-format fix is `a5648d0`. `tests.yml` names the RED commit.

## Ambiguities that block safe progress
None.
