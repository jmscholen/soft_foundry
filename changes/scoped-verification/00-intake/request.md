# Change Intake

## User intent
Field feedback from an engagement in the `my_ai` repository (a Rails application using Soft Foundry): verification was over-repeated. Rounds that should have taken 1.5-2 hours took 5-6 because every code change staled every change's evidence on the branch, every record's verify re-ran the same 11.5-minute full suite on identical code, and every change ran the same full-size checks whatever it touched. This is change A of three stacked changes answering that feedback (items 1-3 of 7). B (items 4-6: `phase reopen`, parallel phase runs, a released state) and C (item 7: smaller fixes) follow.

## Desired outcome
1. **Scoped staleness.** A change declares its scope (affected paths). Its commit-bound evidence is stale only when a changed file is inside that scope or inside a repository-declared shared core. A shared-core change still stales every record; an isolated change stales only its own.
2. **Full-suite result reuse.** A full-suite run is recorded keyed by git tree hash. A verify on an identical tree references the existing run instead of re-running it, and its own checks focus on the change's acceptance criteria.
3. **Check sizing by policy.** A policy under `.ai/policies/` says: a change touching only its own scope runs targeted checks plus one full-suite run before merge; a change touching shared core runs the full suite at verify, computed from the diff, not judged by hand. Evaluate and attack follow the same split: the touched doors plus a sign-in/app-wide smoke test, with a full route sweep only when the change alters access control.

## Constraints
- Shared core is declared per repository (for Rails: ApplicationController, User, auth and paywall code), never hardcoded in Soft Foundry.
- No check that found a real bug may be dropped. The default for a change with no declared scope stays the current behaviour (any code change stales), so existing records and repositories are unaffected.
- Soft Foundry does not run an application's test suite; reuse means recorded evidence the verification phase cites, with the gate checking the tree hash and the result.
- `gate` stays structural (see memory: gate checks structure, not content); the change must not imply a passing gate proves the suite passed.
- Control-plane changes follow the usual path: templates, `check`, harness evals, `.ai/README.md` and `schemas.md` kept in step.

## Non-goals
Items 4-7 (phase reopen, parallel runs, released state, smaller fixes); changing the iterative track; weakening review or judgment.

## Task classification
feature (control plane and CLI).

## Initial risk
high: it changes the rule deciding when evidence is still valid, so a mistake silently lets stale evidence pass. High risk keeps it on the gated track with no waivers.
