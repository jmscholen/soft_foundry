# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and `.ai/rules/errors.md`, REQ-016, and `12-observability/`. `surfaces.observability` is false. There is no deployed service, so the standard dashboard, alarms, and metrics in the observability template are not owed by this change. The observe phase is optional (`workflow.yml`) and still the untouched template. The operator surface is the CLI in a terminal or a CI log.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-009 | minor | test suite when `SOFT_FOUNDRY_PHASE` is set (VER-001) | Verification's full run that inherited `SOFT_FOUNDRY_PHASE=verify` from the phase runner reported 12 failures and 1 error (`ReleaseStateTest`, `ApplicationRepoTest`, `CrossCliHooksTest`, `GuardTest`, `GuardIndirectionTest`). The same behavior was recorded on `cf932d1` and kept, because the remediation did not touch it. The tree at `44efb99` passed with the variable unset: 822 runs, 6228 assertions, 0 failures (`06-verification/evidence/full-suite.txt`). The guard and release-state code read that variable, and the suite does not clear it. This predates the features in this change. The passing run is the one recorded as CHECK-001. | A phase session runs `bundle exec rake test` without unsetting `SOFT_FOUNDRY_PHASE`. The suite fails on tests that pass in a normal shell, so the session records a red suite for a green tree. | `.ai/rules/testing.md` (tests isolated from uncontrolled environment); VER-001 |
| REV-010 | minor | `lib/soft_foundry/cli.rb` `parallel_run` | See the functional review. The searchable lines are present (`phase attack: fail`, `parallel: ... 1 failed`). The process status of that same run is 0 when the session wrote `blocked` itself. A job that only checks the exit code does not detect it. The runner-marked case prints `blocked:` and exits 2. | Same as REV-010 in `functional.md`. | REQ-016; `.ai/rules/observability.md` (a material failure mode needs a detection path); `.ai/rules/errors.md` |

## Conformance

Conforms with REV-009 and REV-010.

A single run, an auto-reopened run, and a parallel run that the runner marks blocked exit nonzero and print `blocked:`. `change summary` prefixes and the gate's `protection stated` line are plain text and stable. A failed mark prints `warn:` and leaves the handoff for the gate. No service metric, dashboard, or alarm was added, which matches the specification for a library with `surfaces.observability: false`. Rollback remains a revert of the gem; no migration or release step is required beyond the 0.22.0 version constant.
