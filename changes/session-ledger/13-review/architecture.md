# Architecture Review

## Scope reviewed

Rules loaded, the same set implementation declares and discovery selects:

- Baseline: `.ai/rules/general.md`, `architecture.md`, `security.md`, `errors.md`, `dependencies.md`, `observability.md`, `git.md`, `learned.md`.
- Discovered: `.ai/rules/ruby.md` (language) and `.ai/rules/testing.md` (minitest). No framework and no database are recorded in `.ai/repository.yml`, so `rails.md` and `database.md` do not apply. No Infrastructure-as-Code tool is recorded; `infrastructure.md` was read and is applied in `infrastructure.md` of this review.
- `.ai/rules/accessibility.md` because `surfaces.accessibility` is true.
- `.ai/rules/policy-conformance.md` was read because the change retains new local data; see `policy-conformance.md`.

Code structure reviewed: `SessionLedger` as the index, `Hooks` as the user-level installer, `CLI` as the only delivery surface, `PhaseRunner` for session identity, `Guard` for the tool-name map, `Snapshot` plus `app.js` for the page. No new gem. No new process, queue, or network client.

## Findings

| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-ARCH-001 | minor | `.ai/schemas.md`, `.ai/templates/handoff.yml`, `README.md` | Implementation edited `CONTROL_PLANE` files and `README.md`, which its skill cannot write. The deviation is recorded in `05-implementation/deviations.md` and is real: those paths are outside the implementation write set, and the edits went through the shell, which the guard checks against deny sets only. | `.ai/rules/general.md` (changes outside the approved scope are documented deviations). `.ai/skills/implementation/permissions.yml` denies `CONTROL_PLANE`. |

## What conforms

`SessionLedger` is a small class with an explicit lock, rename, and failure path. The CLI is the delivery edge; the ledger does not know about HTTP or the UI. `Snapshot` is the one reader that crosses into the page, which matches how the UI already gets its data. `Git` is the existing wrapper, called with `GIT_DIR` and `GIT_WORK_TREE` cleared. No cyclic dependency, no new abstraction layer, no unused API.

Ruby: keyword arguments where the call site would otherwise be unclear, no metaprogramming, no `rescue Exception`. `session_log` rescues `StandardError` and `ScriptError` and returns 0. That is the strategy REQ-SL-005 requires, not an unexplained swallow. The general rule against converting failure into success still applies to every other new command; REV-FUN-001 is the place it does not.

Testing: RED `d278ecf` before GREEN `98b55d1`, and RED `88eee99` before the remediation GREEN `93acd89`. Learned rules `commit-the-failing-test-first` and `regenerate-evidence-never-annotate` were followed. Verification, evaluation, and attack were rerun at `93acd89` rather than annotated. No dependency was added.

The two post-RED test edits are accepted. They correct a fixture that matched every search, and they allow the `warn` word the doctor line is specified to print. Neither lowers an acceptance criterion.

REV-ARCH-001 is accepted as an exception for this change, not sent back. REQ-SL-015 requires README, help, and `.ai/schemas.md` to describe the ledger and `executed_by`, and no skill's write set covers those files. The diff is the new `executed_by.session_id` and `cwd` sentences in the schema and the handoff template comment, plus the README section. Content matches the code. The maintainer still accepts the control-plane edit at merge; this review does not widen the implementation write set.

## Conformance

Conforms with advisories. REV-ARCH-001 is an accepted permission exception with a specification reason, not an unreviewed structural change.
