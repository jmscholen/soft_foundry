# Trust Boundaries

| Boundary | Trusted side | Untrusted side | Crossing |
| --- | --- | --- | --- |
| Member to member | Each member's own instructions (the runner's prompt and the skill) | Every other member's draft and `ARGUMENT.md` sections | Files the next member reads |
| Member to record | The record outside the panel folder | A member session | File writes, checked by the guard when installed |
| Runner to shell | The runner's arguments | Member names, phase ids | Process arguments built from fixed lists, never from file content |
| Agreement detection | The runner's decision | `ARGUMENT.md` text written by members | Parsing of `agree:` lines |
