# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| Command lines | The fields `Processes` reports | Whatever any process of this user put in its own arguments | Recognition by executable position; per-field validation; arguments after `--` dropped; never the raw line (MIT-001) |
| Subprocesses | `ps` and `lsof` with fixed arguments | Values from requests or from command lines | Argument arrays, no shell; the pid is digits from a pattern (MIT-002) |
| The page's origin | The page | Other origins | The existing refusals apply to the new route (MIT-003) |
