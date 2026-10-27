# Unknowns

| Unknown | Impact if wrong | How to resolve | Blocking? |
| --- | --- | --- | --- |
| Authoritative source of the task-type and risk vocabularies (template comments only; no constant; `.ai/policies/` task and risk policy files not opened in full) | `--type`/`--risk` could accept values policy rejects, or reject valid ones | Specification reads the task-classification and risk policies and chooses one source of truth (policy file or a constant the check also lints) | no |
| Exact `blocked` wording and where the runner records it (`blocking:` entry, `notes`, or `executed_by`) | Gate `blocking recorded` needs a non-empty `blocking`; a note-only record would fail it | Specification decides; the existing `blocking` list already satisfies the gate | no |
| Whether blocked-marking also applies to `--parallel` runs and auto-reopened runs | Inconsistent behaviour across run paths | Both call `finish!` (`cli.rb:1120`, `1233`); specify one behaviour for both | no |
| Latest-state summary: command name, layout, and whether it runs the gate or reads recorded handoffs | Slow or stale-looking output; accessibility regressions | Specification decides; accessibility rule applies; `Snapshot#recorded_cell` offers the fast path, `evaluate_all` the true one | no |
| What "newest finding counts" means per phase (handoff `findings:` lists, review and attack evidence files differ in shape) | Misleading counts | Specification names the sources per phase; plan inspects real records | no |
| Which skills receive the invisible-character guidance and whether the README gains text | Guidance missed where payloads are quoted (attack, review, verification) | Specification and plan; skill edits belong to implementation under its permissions | no |
| How parity state is recorded in `tests.yml` (field name, allowed values, how "in force" is stated) and whether the gate also requires it for evaluation and attack | Gate could demand more than the intake allows, or too little | Specification; intake limits the gate to checking the verification record states the protection state | no |
| Which skill may edit `.ai/rules/` and `.ai/skills/` text for this change (discovery, specification and verification deny those paths; implementation permissions not read here) | Plan may route work to a phase that cannot write it | Plan confirms against implementation's `permissions.yml` | no |
| Harness-eval case contents (denied to this skill) | Cannot say whether an existing gate case covers blocked-complete handoffs (README line 342 says one does) | Later phases with read access, or the maintainer, confirm | no |
| Semver bump and release notes for the new flags | Version drift | Plan, per existing release practice | no |
| Whether Soft Foundry's own records gain risk from the parity check (this repository declares no `access_control`) | Intake constraint violated | Specification makes the check apply only when the profile declares `access_control` and a changed path matches | no |
