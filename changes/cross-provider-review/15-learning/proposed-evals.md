# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| HEVAL-XP-001 | `phase run review` with no `--shell` on a record whose implementation provider is known and remediation's is not | REV-FUN-001 | The chosen shell's provider differs from the known one |
