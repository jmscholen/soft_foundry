# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Filter in `entries`, the one read path | Filter in each command | Every lookup (CLI, runner, UI) already reads through `entries` | One check covers all paths; `update` still keeps untrusted lines in the file |
| Quote the ID as well as filter it | Filter only | Defense in depth on a command people paste | Real IDs are plain identifiers, so their printed commands do not change |
