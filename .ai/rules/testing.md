# Testing Standard

- Tests must verify externally meaningful behavior and important invariants, not merely mirror implementation structure.
- Every material defect fix should include a regression test at the lowest useful layer.
- Do not weaken, delete, skip, or rewrite expectations to accommodate a failing implementation without an approved requirement change.
- Tests should be deterministic and isolated from uncontrolled external services.
- Exercise authorization boundaries, invalid input, error paths, retries, persistence, and concurrency where material.
- Prefer realistic integration coverage for behavior that spans components.
- Test fixtures/factories should communicate intent and avoid irrelevant setup.
- For a feature, fix, or refactor, write the test first and commit it before the implementation: one commit in which the test exists and fails (RED), then the commit that makes it pass (GREEN). Verification names the RED commit as `red_commit` (with `test_path`) on the check that covers it, and the gate verifies the shape of that claim against git. A change verified with no RED commit is advised as lacking failing-test-first evidence.
