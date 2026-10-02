# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| ui-change-opened-in-a-browser | An agent building a page loads it in a browser before recording evaluation | The cross-site refusal defect | The evaluation evidence contains observations from a running page, not only request transcripts |
| attack-runs-against-a-live-process | An agent attacking a network service starts it and sends real requests | ATTACK-005 | The attack evidence contains a transcript against a listening process |
