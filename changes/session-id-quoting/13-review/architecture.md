# Architecture Review

## Scope reviewed

`lib/soft_foundry/session_ledger.rb` against `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, `.ai/rules/errors.md`, and `.ai/rules/dependencies.md`. Call sites that read sessions: `CLI#sessions`, `CLI#resume`, `Snapshot#recorded_sessions`, `PhaseRunner#recorded_session`. No new type, gem, or process.

Rules loaded, matching implementation's baseline plus discovery: `general.md`, `architecture.md`, `security.md`, `errors.md`, `dependencies.md`, `observability.md`, `git.md`, `learned.md`, `ruby.md`, `testing.md`. No framework and no database are recorded in `.ai/repository.yml`, so `rails.md` and `database.md` do not apply. `accessibility.md` and `policy-conformance.md` are applied in their own files. `infrastructure.md` is applied in `infrastructure.md` and does not attach to this diff.

## Findings

None.

## What holds

The trust decision sits on `entries`, the one method every lookup already used. Commands do not each grow a copy of the check. Quoting sits on `resume_command`, which already owned the paste string, so the CLI and the snapshot cannot drift. That matches the decision in `05-implementation/decisions.md`.

`SessionLedger` already builds a shell command. Using `Shellwords` for the id is the same coupling the folder quoting had, and it is the point of the class, not a new delivery-layer leak. `trusted?` is a small predicate with no metaprogramming, no new dependency, and a `JSON::ParserError` rescue that was already there. Other exceptions still propagate. Rejected lines are skipped, which is the specified fail-closed behavior, not a swallowed error turned into a successful resume.

`trusted?` is narrower than the sentence above it. `record` also strips control characters from `cwd` and prompt excerpts. The predicate does not re-check those fields. That does not break the layering. It means the comment oversells "one `record` could have written." The security file states what that leaves in place.

The public surface gained one method, `trusted?`. Nothing outside `entries` needs it. Leaving it public is harmless and keeps the invariant nameable.

## Conformance

Conforms. The change follows the existing ledger boundary, adds no abstraction, and does not depend on a new delivery mechanism.
