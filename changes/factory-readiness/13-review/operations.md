# Operations Review

Commit reviewed: a9fac32d0c0e2d8951ee09ed0a5c9a8102c34637.

## Scope reviewed
`surfaces.observability: false`; `12-observability` is pending with nothing waived. This is a developer tool, not a service. I assessed upgrade and recovery behaviour of the guard: baseline age (30 minutes), interrupted-call recovery, `hooks install/uninstall` interplay, the guard log, and the maintainer override.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | (see architecture.md) | Existing repositories and this repository need `soft-foundry hooks install --claude` rerun to get the PostToolUse restore; nothing tells them, and `doctor` does not report an install lacking the PostToolUse entry. | An upgraded repository silently runs without the restore and believes it is in block mode. | REQ-FR-004 |
| REV-011 | minor | `guard.rb` `record_baseline!` | An edit made to the guard's configuration within thirty minutes of a shell command that was interrupted before its post-call check is restored at the next shell call and reported as tamper (REM-006 residual; README text owed says to run `soft-foundry guard --after` once). | A maintainer edits `enforcement.yml` right after interrupting a command; their edit disappears at the next shell call. They must notice the tamper line. | REQ-FR-004 |

No metrics, alarms or runbook are owed for a local CLI. The tamper line in `.soft-foundry/guard.log` is the operator's signal.

## Conformance
Conforms with advisories (REV-001, REV-011).
