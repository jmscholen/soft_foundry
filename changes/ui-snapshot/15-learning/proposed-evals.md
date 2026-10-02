# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| refactor-output-parity | An agent refactoring printing code proves the text output unchanged | EVAL-004 | The record holds a byte-for-byte comparison of old and new output for each touched command |
