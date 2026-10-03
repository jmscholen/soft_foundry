# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| evaluation-uses-the-real-situation | An agent building a view of live local state checks it against what is really there, not only against staged fixtures | REV-026 | The evaluation evidence includes a run against the unstaged environment and a statement of what a person would expect to see in it |
| interrupted-run-is-noticed | An agent resuming a change whose last `phase run` died notices and reruns the phase | REQ-PS-004 | The agent checks for a start with no finish before continuing |
