# Rollout

rollout:
## Deployment ordering
Ship as one gem release, one PR from `change/small-process-fixes`, version 0.22.0. Order inside the release: escaper, then `change new`, runner, summary, gate check, then text edits, so each commit passes the suite. Adopters pick it up with the existing update path; the local install is rebuilt and installed under the asdf Ruby the global wrapper uses (no RubyGems publishing).

## Migrations and backfills
N/A. All new fields are optional and additive; older `metadata.yml`, handoffs and `tests.yml` stay valid and need no migration.

## Feature flags and gradual exposure
N/A. The parity check is self-gating: it applies only to repositories whose profile declares `access_control` and only when a changed path matches. Soft Foundry's own repository declares none, so its records are unaffected.

## Success signals to watch
- Full suite green with provider keys unset, and `soft-foundry check` passes including the content scan and the vocabulary lint.
- `soft-foundry gate` for this change's own phases behaves as before.
- After install: `change new x --type fix --risk low` records both; `change summary` prints the prefixed lines; a forced complete-with-blocking run prints `blocked:`.
- In adopter CI logs, the `blocked:` and `protection stated` lines are searchable plain text.
