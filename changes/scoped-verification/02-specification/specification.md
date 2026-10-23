# Specification

## Intent
Verification was over-repeated in the field because the staleness rule is repository-wide, the same full suite is re-run for identical code, and every change runs checks of the same size. This change makes evidence staleness per change (declared scope plus a repository-declared shared core), makes a full-suite run a recorded, tree-keyed fact later verifications cite, and computes check size from the diff under a policy. Default behaviour (no declared scope) is unchanged. Soft Foundry never runs the application's suite and the gate stays structural (REQ-008).

## Personas and authorization boundaries
- Maintainer or developer: declares scope in a change record and shared core and access-control globs in the repository profile; reviews those declarations.
- Implementing agent session: edits code; may declare scope for its own change but cannot weaken the repository declarations, which live in `.ai/` and are protected from execution skills (REQ-013 makes any later edit of a declaration stale the evidence).
- Verification, evaluation and attack sessions: read the computed size, record or cite a full-suite run; they cannot alter another phase's evidence.
- No authentication or authorization exists; this is a local CLI. The boundaries that matter are the runtime guard and protected paths, which are unchanged.

## Functional behavior
1. Scope (REQ-001, 003, 004): `metadata.yml` carries an optional list of path globs. Absent or empty means whole repository.
2. Shared core (REQ-002): the repository profile carries an optional list of globs; a changed path matching it stales every record.
3. Staleness for a scoped record (REQ-003, 005): a changed code path stales it if it matches the record's scope, the shared core, or is unclaimed (matches no record's scope and not the shared core). A path claimed only by another record's scope does not. The specification re-record cause and the stacked-branch diff base are untouched.
4. Declaration changes (REQ-013): editing the record's scope, shared core or access-control globs after the evidence commit stales the evidence.
5. Full-suite run record (REQ-006, 007, 017): verification evidence may hold the tree hash of its evidence commit, the command and the outcome, or cite another record's run. A citation is accepted only when the tree hashes are equal, the cited outcome is passed, the cited record exists and no code path is dirty. Otherwise the check fails and names the fix (run and record the suite).
6. Check sizing (REQ-009 to 012): a policy file defines sizes, computed from the diff and the declared globs. Verify: targeted plus one full run before merge if the diff is inside scope; full at verify if it touches shared core or leaves the scope. Evaluate and attack: touched doors plus a sign-in and app-wide smoke test, full route sweep only if the diff touches an access-control glob; no access-control declaration, or no scope, means full. A command reports the size and triggering paths; the gate refuses evidence recording a smaller size than computed.
7. Advisories (REQ-018) warn without blocking.

Decisions closing the discovery unknowns: scope in `metadata.yml`; shared core and access-control globs as keys in `.ai/repository.yml`; unclaimed code paths stale all scoped records (safer); dirty worktree refuses reuse; the full-suite run lives in the verification record (`tests.yml`) and is cited by record slug, found under `changes/`; access control is path-declared only (REQ-015); sizing uses the same diff base as staleness (REQ-011).

## Accessibility
The change alters CLI output a person or screen reader consumes. REQ-021 applies the command-line rules of `.ai/rules/accessibility.md`: outcomes as words, one fact per line with a stable prefix, meaning intact without color or non-ASCII, no prompts, errors that say what to do next. REQ-022 covers the browser view's text-not-color rule for scope and staleness. Reports changed or added use real heading hierarchy.

## Data and consistency
Optional new fields only (REQ-023): metadata `scope`, repository `shared_core` and `access_control`, full-suite fields in `tests.yml`, a policy file. The tree hash is the identity of tracked content; ignored and untracked files are outside it, which is why a dirty worktree refuses reuse. Records without the fields behave as today.

## Failure behavior
Unknown commit, missing tree or unreadable branch fail closed: stale or check failure with a named cause (REQ-016). A tree mismatch after a squash or rebase fails reuse and the suite is re-run (REQ-017). A blind or malformed declaration is refused by the structure check (REQ-014). No check is dropped (REQ-012).

## Security requirements
The high-risk failure is stale evidence silently passing. Controls: unclaimed paths stale, declaration edits stale (REQ-013), blind-declaration refusal (REQ-014), fail-closed git errors (REQ-016), path-only matching with no content inference or execution (REQ-015), and the gate never implying a suite passed (REQ-008). Review and judgment remain unwaived.

## Privacy and security policy conformance
Nothing the application's privacy policy, security policy or terms cover changes (REQ-026): the tool is a local CLI, collects and shares no user data, and each policy is recorded NOT_APPLICABLE in `.ai/repository.yml`. `surfaces.policy` is false.

## Performance and resource limits
A bounded number of git calls per gate run regardless of changed-file count (REQ-024); no test execution by Soft Foundry. The motivating saving is one full-suite run per tree instead of one per record.

## Infrastructure implications
None (REQ-025): no deployment, database or dependency. CI runs unchanged.

## Observability expectations
Output states the applied scope, causing paths and reasons for stale and size results; status shows the scope (REQ-020). Advisories surface core-without-full-run and scope overrun (REQ-018). Consumers follow the single scoped result (REQ-019).

## Acceptance criteria
AC-001 to AC-022 in `acceptance-criteria.yml`; each maps to requirements and later to verification, evaluation or attack evidence.
