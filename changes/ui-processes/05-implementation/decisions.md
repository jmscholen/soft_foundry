# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Read the process table | A registry file each command writes and removes | Finds processes already running, in repositories on older versions, and after a crash leaves no stale file | Depends on `ps` and on how the process was started; a spoof can appear |
| Machine-wide for this user, with "here" marked | Only the viewed repository | The request was for any process and multiple sessions; the maintainer runs sessions in several projects | Other repositories' paths and changes are shown |
| Report validated fields, never the line | Show the command line, escaped | A line can hold a prompt, a token, or anything a process chose | Unknown values are dropped silently (a spoof shows as "phase run" with no phase) |
| Interrupted runs from `executed_by` | Nothing; or infer from handoff status | The runner already stamps start and finish; a start with no finish and no process is exactly a dead session | Only runs through `phase run` can be called interrupted |
| Change from the branch when not named | Leave it empty | `phase run` and `gate` are usually run without `--change` | One `git` call for such a process |
| `soft-foundry ps` as well as the view | View only | The same data in a terminal, testable without a browser, usable in a script with `--json` | A new command |
| The page reads the process list on every poll | Only on the Running view | A change should say what is running on it without a second click | One more request per poll, reused for 2 s by the server |
| The server's own row is shown, dimmed and labelled | Hide it | It is a soft-foundry process; hiding it makes the count disagree with `ps` in a terminal elsewhere | Counts in sentences exclude it |
