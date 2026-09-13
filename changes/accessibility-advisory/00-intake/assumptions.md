# Assumptions

## Explicit assumptions
- "Goes live" means the change merging and shipping, so `change close` is the last moment to say what is still owed; the same advisories appear on every `gate`, `change status`, and `ci` run before that so nobody is surprised at close.
- WCAG 2.2 Level AA is the right default for any UI a governed repository renders. A repository may name a stricter or more specific standard in its own rules; the standard says the stricter one wins.
- "User-facing framework" is the list already detected by the maturity scan: rails, sinatra, express, next, react, vue, angular, django, flask, fastapi. A library-shaped repository (this one) stays `false` and the author sets the flag by hand when a change is user-perceivable, as this change does.
- The maintainer's instruction "report, don't block" is applied uniformly: the accessibility findings and the review/judge skip notices are all advisories. An `advisory:` block is therefore expected on this change's own gate output, since it skips `judge` with rationale.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, and the review phase is run for it because the change is about review. That choice is recorded here rather than silently taken.

## Ambiguities resolved
- Whether a skip with an empty rationale should be advised as a skip: no. It is not a skip (the gate already treats it that way); the phase stays required and the gate reports it as pending.
- Whether advisories should print for closed records in `ci`: no. `ci` already skips closed records entirely to avoid stale-evidence noise; advisories for a record that is already live are history, and `change close` printed them at the go-live moment.
- Whether `check` should error on a missing standard: no. The maintainer asked for reporting, and an installed plane without the file still works; it is a warning.
- Whether to preserve the template comment on the `accessibility:` line when `change new` sets it: the line's own comment is replaced by one saying who set it and why; every other comment in the file survives.

## Ambiguities that block safe progress
None.
