# Implementation Log

## Changes made
- `test/red_green_test.rb` (new, committed first at `5d898e0` as RED): nine tests for the gate check and the advisory.
- `lib/soft_foundry/gate.rb`: `red_evidence_check` on the verification phase (commit exists, not the verified commit, ancestor, test file present at RED, code changed after; skip when no check names a RED commit; fail on invalid YAML); `require "yaml"` and `"date"` so the file stands alone.
- `lib/soft_foundry/git.rb`: `file_at?(sha, path)`.
- `lib/soft_foundry/advisory.rb`: `red_evidence_notices` for a completed verification of a feature, fix, or refactor with no `red_commit` on any check.
- `.ai/skills/verification/template/tests.yml`: the two optional fields, commented. `.ai/rules/testing.md`: the failing-test-first rule. `.ai/skills/implementation/SKILL.md` and `.ai/skills/verification/SKILL.md`: what each phase does with it.
- `README.md` ("RED and GREEN evidence"), `.ai/schemas.md` (the gate check and the advisory), `.ai/repository.yml` (`evidence.failed_results_retained` finding), `.ai/maturity.yml` (its rule).
- Version bumped to 0.12.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- Doing the change test-first produced its own evidence: `06-verification/tests.yml` names `5d898e0` as `red_commit`, and the gate's `red evidence` check on this record is the feature checking itself. `evidence/red-at-5d898e0.log` is the test file run at that commit: nine runs, eight errors.
- The RED commit's tests had two helper-level mistakes (no `test/` directory in the fixture, a braces-less hash passed where Ruby expects keywords). Both were fixed with the implementation without changing any expectation. Test-first does not mean the test file is finished first; it means the expectations are.
- The evaluation script's first run wrote a literal `\n` into `tests.yml` (printf `%s`), so every RED step reported invalid YAML. The transcript was regenerated after fixing the script; the invalid-YAML path it accidentally exercised behaves as designed and is now a test.
- The new advisory immediately reports on the two earlier open records in this series (runtime-guard, phase-runner): neither was done test-first. That is the feature working on itself, and the review says so.

## Challenges
None substantive.
