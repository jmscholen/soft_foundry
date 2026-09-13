# Implementation Decisions

See `log.md`'s "Decisions" table for the substantive design decisions (environment-detected billing mode, per-shell detection, machine-local warning interval, record-time warnings, over-cap exit code, YAML-safe template substitution).

## Additional decision found mid-implementation
| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Flush stdout/stderr before handing off to the shell launcher | Set `$stdout.sync = true` globally in the executable | A targeted flush at the one exec-style handoff keeps the CLI's output behavior otherwise unchanged and is testable in isolation | The regression test injects an IO that records the flushed buffer at launch time |
