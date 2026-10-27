# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and `.ai/rules/errors.md`, REQ-016, and `12-observability/`. `surfaces.observability` is false. There is no deployed service, so the standard dashboard, alarms, and metrics in the observability template are not owed by this change. The observability phase is optional and still the untouched template. The operator surface is the CLI in a terminal or a CI log.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `lib/soft_foundry/cli.rb` `parallel_run` | See the functional review. The searchable lines are present (`blocked:`, `phase evaluate: fail`). The process status of that same run is 0, so a job that only checks the exit code does not detect the blocked phase. | Same as REV-001 in `functional.md`. | REQ-016; `.ai/rules/observability.md` (a material failure mode needs a detection path); `.ai/rules/errors.md` |
| REV-009 | minor | test suite when `SOFT_FOUNDRY_PHASE` is set (VER-001) | Verification's first full run inherited `SOFT_FOUNDRY_PHASE=verify` from the phase runner and reported 12 failures and 1 error (`ReleaseStateTest`, `ApplicationRepoTest`, `CrossCliHooksTest`, `GuardTest`, `GuardIndirectionTest`). The same tree passed with the variable unset: 821 runs, 0 failures (`06-verification/evidence/full-suite.txt`). The guard and release-state code read that variable, and the suite does not clear it. This predates the features in this change; the verification session is what surfaced it. The passing run is the one recorded as CHECK-001. | A phase session runs `bundle exec rake test` without unsetting `SOFT_FOUNDRY_PHASE`. The suite fails on tests that pass in a normal shell, so the session records a red suite for a green tree. | `.ai/rules/testing.md` (tests isolated from uncontrolled environment); VER-001 |

## Conformance

Conforms with REV-001 and REV-009.

A blocked single run exits 2 and prints `blocked:`. `change summary` prefixes and the gate's `protection stated` line are plain text and stable. A failed mark prints `warn:` and leaves the handoff for the gate. No service metric, dashboard, or alarm was added, which matches the specification for a library with `surfaces.observability: false`. Rollback remains a revert of the gem; no migration or release step is required beyond the 0.22.0 version constant.
