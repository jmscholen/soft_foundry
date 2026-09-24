# Implementation Log

## Changes made
- `test/learning_instincts_test.rb` (new, committed first at `a5c0d59` as RED): nine tests for the template, the gate check, `learn list`, `learn promote`, the policy threshold, and the baseline rule.
- `lib/soft_foundry/learning.rb` (new): `Instinct`, `problems` (per-entry validation), `read` (one record), `all` (every record, closed included, by confidence), `min_confidence` (policy), `promoted_ids` (headings in `learned.md`), `section`, `promote!` (through `SafeWrite`).
- `lib/soft_foundry/gate.rb`: `instincts_check` on the learning phase.
- `lib/soft_foundry/cli.rb`: `learn list` and `learn promote` (refusal outside a record or on a closed one; skip lines for already-promoted and below-threshold; dry run; the "wrote ... through change" line); help text.
- `.ai/skills/learning/template/instincts.yml` (new), `completion.yml` (requires it), `SKILL.md` (what an instinct is and who promotes). `.ai/policies/learning.yml` (new, `promote.min_confidence: 0.8`). `.ai/rules/learned.md` (new, header only). `.ai/skills/implementation/skill.yml` and `.ai/skills/exploration/skill.yml`: `learned.md` in the baseline rules. `.ai/rules/README.md`: the file described.
- `README.md` ("Instincts: what a change learned"), `.ai/schemas.md` (the gate check), `.ai/maturity.yml` (three rules), `.ai/repository.yml` (three capabilities to PASS, one finding named).
- `changes/learning-instincts/15-learning/`: this change's own learning phase, completed with six instincts from this series.
- Version bumped to 0.13.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- This is the first record in the repository to complete its learning phase, and it did so with instincts about the series that produced it: test-first commits, checkout-first hooks, staleness on the record's branch, regenerating evidence rather than annotating it, checking that a commit landed before binding evidence, and branching from the record branch when stacking. They are in `15-learning/instincts.yml` with their evidence, and the next change can promote the ones above the threshold.
- The evaluation script's first run branched the promoting change from `main`, which had no records, so `promote` had nothing to promote and printed nothing; that was the script, not the tool, and became one of the instincts.
- `learn list` printed "when when" because triggers already start with "when"; a one-line format fix (`a5648d0`) after the GREEN commit, which moved the evidence-bound commit and meant regenerating the verification evidence once more.

## Challenges
None substantive.
