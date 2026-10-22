# Deviations From Plan

## DEV-001: control-plane files not written (requires a person with write access to `.ai/`, docs and `README.md`)
What changed: plan steps 6 (the policy file `.ai/policies/check-sizing.yml`), 10 (template fields, the `SKILL.md` additions, `.ai/workflow.yml` rules entry, `.ai/README.md`, `.ai/schemas.md`, `README.md`, the harness-eval cases) and the template part of 9 were not done.
Why: this phase's permissions.yml denies writes to `${CONTROL_PLANE}` (`.ai/**`) and `${DOCS}`, allows none for the root `README.md`, and denies reading `${HARNESS_EVALS}`; the runtime guard refused a read of `.ai/policies`. Doing them anyway would break the skill contract.
Requirements affected: REQ-009 (policy file under the policies directory), REQ-023 (templates, evals and control-plane documents changed together), REQ-008 and AC-010 for the document half (the sentence that a passing gate shows a recorded run names this tree), AC-021 (docs, evals, templates described and passing). The code half of each is implemented and tested.
Who must approve: the person who owns the repository, or a later change/phase with control-plane write access. Proposed text for every owed file is in `owed-control-plane.md` in this directory, so nothing needs to be redesigned.
Mitigation in code: `Sizing` falls back to built-in defaults with the same four names when the policy file is absent and fails closed when it is malformed; `check` validates the policy when it exists; `check` does not require the new template fields, so the repository stays valid in the meantime.

## DEV-002: test fixtures corrected after the RED commit
What changed: three fixture or setup corrections in `test/scoped_verification_test.rb` after commit `8287d58`, no expectation weakened:
1. Two records that cite one another share a tree only if their evidence commit is the same commit (the tree includes each record's own files); the fixture now gives the cited and citing record one evidence commit.
2. The stacked-branch sizing fixture forks the second branch from the record's branch, as `test/stacked_branch_test.rb` does, so the record exists on the checked-out branch.
3. `test_there_is_one_staleness_implementation` asserted a source-file list; replaced by `test_consumers_hold_no_staleness_logic_of_their_own`, which asserts the consumers (phase runner, snapshot, CLI, advisory) contain no staleness text and read the gate's result.
Also: a scoped record in the status test records `size: full_at_verify` and a recorded full run, because another record's commit on the same branch puts the diff outside its scope.
Requirements affected: none. Who must approve: verification may re-judge the fixtures.

## DEV-003: `Git#diff_paths` returns paths only
The plan wrote `diff_paths` as returning `[paths, ok]` or raising; it raises on failure and returns the sorted path list on success. Same guarantee, simpler caller. No requirement affected.
