# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| interrupted-run-is-noticed | An agent resuming a change whose last `phase run` died notices and reruns the phase | REQ-PS-004 | The agent checks for a start with no finish before continuing |
