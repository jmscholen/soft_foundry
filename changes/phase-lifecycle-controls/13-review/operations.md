# Operations Review

## Scope reviewed

Loaded `.ai/rules/observability.md`. There is no deployed service (`observability.*` capabilities in `.ai/repository.yml` are `NOT_APPLICABLE`). Checked how a person detects a reopen, a release, and a discharge after the fact: `snapshot.rb` timeline, `change status`, `ci`, `ps`, `README.md`, `.ai/README.md`, `.ai/schemas.md`, `.ai/workflow.yml` `isolated_phases`, the metadata template, `docs/user/README.md`, and `.ai/harness-evals/cases/`. The observability phase of this change is still pending, which matches an optional phase and the absence of a service. `12-observability/` and `10-user-documentation/` are still the templates.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-004 | minor | `docs/user/README.md`; `.ai/harness-evals/cases/` | `docs/user/README.md` is still the stub and does not name `phase reopen`, `--parallel`, `--env`, `change release`, or `change discharge`. The branch adds no harness-eval case for a malformed release block, a non-isolated parallel request, or a stale auto-reopen. `README.md`, the CLI usage text, `.ai/README.md`, `.ai/schemas.md`, and `.ai/workflow.yml` do name the commands, and `soft-foundry check` passes. `HarnessEval::STATUSES` includes `released`. | A person who follows `docs/user/` as the product knowledge base never reads the session-marker residual or the `--env` isolation warning. `soft-foundry eval` does not plant the release-block or parallel refusals REQ-027 names, so a later edit that drops those refusals is not caught there. Unit tests in `test/` still cover the refusals. | REQ-027, AC-045, AC-050 |
| REV-005 | minor | `Cli#status` | Plain `change status` omits phase reopenings. The timeline carries them. See `functional.md`. | A text status log has no reopen record after `phase reopen`. | REQ-026, AC-049 |
| REV-007 | minor | `Processes#phase_of` | `ps` reports one phase, `args[2]`. A parallel invocation's later phase names are dropped. | While `soft-foundry phase run evaluate attack --parallel` is running, `soft-foundry ps` shows the phase as evaluate. An operator looking for the attack phase concludes it is not running. | REQ-021, deviation D10 |
| REV-008 | minor | `SafeWrite` leftover temp | After a killed reopen, retry fails until the named `.soft-foundry-tmp` file is removed. The error says to remove it and rerun. There is no automatic cleanup. `check` can still exit 0 on the half-reset record; `ci`, `change status`, and `change close` notice the pending phase. | SIGKILL `phase reopen` after the first rename (attack drive14). The next command that writes that file refuses, naming the temp. The reason is lost if every handoff was already reset. | REQ-022, `.ai/rules/observability.md` (a new failure mode needs a detection path) |

## What holds

Every successful reopen appends `phase_reopenings` (`at`, `phase`, `reset`, `from_commit`, `reason`, `source`, `previous` as a per-phase map of status, commit, completed_at, and session id). The timeline labels `source: auto` as "automatic" and keeps "reopened for exploring" on the older `reopenings` list. Release and discharge events are on the timeline. `ci` lists open item ids for a released record and does not re-gate it. No metrics pipeline was added, which matches REQ-026.

`.ai/schemas.md` and the metadata template comment describe `previous` as a single status (`previous: complete`). The code stores a map, which is what REQ-004 and AC-005 require. The timeline does not read `previous`, so current output is unaffected. A consumer written only from that sentence would misread the field. Noted here rather than filed: no current command takes the wrong branch because of it.

## Conformance

Conforms with REV-004, REV-005, REV-007, and REV-008. Operational detection for a library gem is the record, the timeline, status, and `ci`. Those surfaces show release and discharge. A completed reopen shows in the timeline. A killed reopen is fail-closed and leaves a temp file the next write names.
