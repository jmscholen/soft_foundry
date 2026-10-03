# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| run-the-owed-test-first | When a record owes a real-world test, the next session runs it before building on the feature | REV-002 | The owed test is run and its result recorded before new work depends on the feature |
