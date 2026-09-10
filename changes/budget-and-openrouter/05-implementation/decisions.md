# Implementation Decisions

See `log.md`'s "Decisions" table for the substantive design decisions (ledger schema, why `budget status` stays separate from `gate`/`ci`, policy resolution timing, over-cap detection semantics).

## Additional decision found mid-implementation
| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| `soft-foundry ci` skips gate evaluation for changes whose `metadata.yml` status is `closed` | Leave `ci` re-gating every change record forever | Committing this change made `init-command`'s already-merged, already-judged evidence STALE, since staleness compares against the current git history regardless of which change touched what. A closed change is a historical record; re-litigating it against unrelated later work serves no purpose and would permanently block commits to any file `init-command` also touched. | `gate <phase> --change <slug>` and `change status <slug>`, invoked explicitly, still perform the real check for anyone who wants to inspect a closed change's historical state; only the automatic `ci`/pre-commit path skips it. |
