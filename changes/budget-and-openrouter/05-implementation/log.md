# Implementation Log

## Changes made
- `lib/soft_foundry/providers.rb`: add `openrouter` (`OPENROUTER_API_KEY`, `https://openrouter.ai/api/v1/models`), default Bearer auth.
- `.ai/policies/budget.yml`: declared spend policy, overridable by risk tier, `declared` (not `metered`) enforcement mode stated explicitly.
- `.ai/policies/human-boundaries.yml`: one line added — exceeding a declared budget cap is a financial commitment requiring approval.
- `.ai/templates/change/budget.yml`: empty-ledger template.
- `lib/soft_foundry/change_record.rb`: `create` now scaffolds `budget.yml` alongside `metadata.yml`.
- `lib/soft_foundry/budget.rb` (new): `Budget` class — read/append ledger entries, sum totals (tokens always, USD only when priced entries exist), resolve policy by risk tier, `over_cap?`.
- `lib/soft_foundry/cli.rb`: `soft-foundry budget status [--change SLUG]` and `soft-foundry budget record --phase --provider --model --tokens-in --tokens-out [--usd] [--change SLUG]`; help text updated.
- `exe/soft-foundry`: added a real Ruby-version guard (`RUBY_VERSION < "3.2"` prints a plain message and exits 1) instead of letting an incompatible interpreter fail with a raw `SyntaxError`. This closes VER-004, a residual-risk item recorded in `init-command`'s judgment, found again by hand while smoke-testing this change with the wrong `ruby` on `PATH`.
- `README.md`: documented `OPENROUTER_API_KEY` and the `budget` commands.
- `lib/soft_foundry/version.rb`: 0.2.0 → 0.3.0.

## Decisions
| Decision | Reason |
| --- | --- |
| Ledger stores tokens and an optional `estimated_usd` per entry, no pricing table | Pricing varies per model/provider and changes over time; recording a table now would drift stale. Whoever records an entry supplies the cost if known. |
| `budget status` is a separate command, not folded into `gate`/`ci` | Keeps this change from touching `gate.rb`/`control_plane.rb`, avoiding the evidence-invalidation cascade that made `init-command` expensive for an unrelated harness fix; budget is informational, not a completion gate. |
| Policy cap resolved live from `.ai/policies/budget.yml` + the change's current `risk`, not snapshotted into the ledger at creation | `risk` is unset at `change new` time and set later during intake; a snapshot would be wrong until intake completes. |
| Over-cap detection only fires when spend is *known* to exceed the cap | Unknown-cost entries are surfaced as a count, not assumed to be zero or assumed to be over; avoids false alarms and false confidence alike. |

## Deviations from plan
None — no separate planning phase ran; this log doubles as the record of what was built, consistent with the lighter-weight process recorded in `00-intake/assumptions.md`.

## Challenges
None substantive. One real bug was found and fixed as a side effect: smoke-testing this change with a bare `ruby` on `PATH` (rather than an asdf-managed 3.3.1) reproduced VER-004 from `init-command`'s own residual risk list — a raw multi-page `SyntaxError` instead of a clean message. Fixed in `exe/soft-foundry` with an explicit version check.
