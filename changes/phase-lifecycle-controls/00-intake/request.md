# Change Intake

## User intent
Field feedback from an engagement in the `my_ai` repository (a Rails application using Soft Foundry) reported friction in how phases are reopened, run, and released. This is change B of two answering items 4-7 of that feedback (A, scoped-verification, shipped items 1-3 in PR #51; C follows with item 7). The maintainer's standing principle applies: the feedback came from one repository, but what ships must work for any adopter, and the process changing itself must not change the intent of the process in another repo. Nothing here is specific to Rails or `my_ai`.

## Desired outcome
1. **Reopen a phase on the gated track.** Today `phase run` refuses any phase marked complete, even when the gate says its evidence is stale. The only reset, `change reopen`, is iterative-track only and wipes everything from implementation onward, so people reset handoffs by hand with `sed`, and mangle the YAML. Add `soft-foundry phase reopen <phase> --reason TEXT`: it resets that phase and its downstream phases, records why in the change's history, and `phase run` calls it automatically when a phase's evidence is stale.
2. **Run isolated phases in parallel.** Evaluate and attack already use private databases and could run together instead of one after another. Add `phase run --parallel` (or a per-run `DATABASE_URL`) so isolated phases run concurrently, with no shared-state corruption of the record.
3. **A released state with named open items.** Today a merged change must be closed or `ci` fails on `main` for everyone, which pushes people to `--no-verify`. Add a `released` status carrying named open items (for example a go-live item still owed), so `main`'s CI passes while the record still shows what is owed before the feature is switched on.

## Constraints
- Generic: no Rails, database engine or repository-specific assumptions in shipped behaviour. A private per-run database must be a mechanism the adopter configures (an environment variable the phase session receives), not something Soft Foundry knows how to create.
- Reopening must never let evidence be forged: it resets handoffs through the tool, records the reason and the reopened commit in the record, and stale or failed gates are still fixed by redoing the work. Reopening must not weaken `implementation_may_not_grade_itself` or any phase's requirements.
- `released` must not become a way to skip closing: it needs named open items, `ci` on `main` must still fail for a merged change that is neither `closed` nor `released`, and a released record with no open items is refused. Close remains the end state.
- Existing records, the iterative track's `change reopen`, and `change close` behave as before.
- Control-plane changes follow the usual path: templates, `check`, harness evals, `.ai/README.md` and `schemas.md` kept in step.

## Non-goals
Item 7 (change C); the scoped-verification follow-ups; parallelising anything but phases that are isolated; changing the iterative track.

## Task classification
feature (control plane and CLI).

## Initial risk
high: it changes how evidence is reset and when a record counts as finished, so a mistake can let stale evidence or an unfinished change pass quietly. High keeps it gated with no waivers.
