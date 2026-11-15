# Operations Review

Standard: `.ai/rules/observability.md`, `errors.md`, `general.md`.

## Scope reviewed
How a person sees and runs the new behavior: `change status`, `change status --json`, the messages at a refusal, the installed gem against the source, and what happened to the guard during the evidence sessions of this record.

## Assessment
- REQ-012 is met: the track is on its own line and each phase that may stay pending says why. `--json` carries `track.name` and `skip_reason`.
- Existing records: a record with no track line reads the default track; gated and iterative records gate as before (EVAL-009, full suite 951 runs, 0 failures).
- Rollback: the track is one entry in `.ai/workflow.yml`. Removing it makes existing light records fail `track permitted` by name, which is a clear failure and not a silent one.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | major (graded in functional.md) | `lib/soft_foundry/sizing.rb` | The saving REQ-007 was written for is not reached on any machine where the tool has run. | See functional.md | REQ-007 |
| REV-007 | minor (graded in functional.md) | `PhaseSeal#advance!` | A judged light record reads `phase: learn`. The guard takes the active skill from `current_phase`, so a session opened on that record is held to the learning skill's permissions for a phase the track does not require. | | REQ-012 |
| REV-011 | minor, outside this change | `lib/soft_foundry/guard.rb` and the PostToolUse hook command (not modified) | When a shell command leaves the working directory inside the record, the after-call hook runs from there, finds no baseline, writes a copy of the committed enforcement policy under `<that directory>/.ai/` and a `.soft-foundry/` beside it, and reports that a tampered policy was restored. It happened in the verification and evaluation sessions and once in this one. The worktree-root `.soft-foundry/enforcement.yml` was not changed. | | errors.md: failures must be classified correctly |
| REV-012 | minor | `lib/soft_foundry/version.rb` | The version is still 0.23.0, the number the installed gem reports, and the installed gem fails `predecessor complete` on this record (VER-005). After merge the gem has to be rebuilt and installed locally before a light-track change works through the global command, and the version number will not show which build is installed. | | general.md: a new failure mode needs a practical way to detect it |

## Conformance
Conforms with the findings above. PC-001 (the maintainer creates one light-track change after merge) remains a person check and is the natural place to confirm REV-012.
