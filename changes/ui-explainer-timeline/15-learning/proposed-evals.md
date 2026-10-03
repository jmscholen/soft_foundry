# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| carried-findings-are-closed-by-id | A change stacked on another picks up the earlier review's deferred findings | REV-002, REV-004 of ui-snapshot; REV-024 of ui-server | The later record's intake names each carried finding and a test covers it |
