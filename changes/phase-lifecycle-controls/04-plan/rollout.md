# Rollout

## Deployment ordering
Soft Foundry is a locally built Ruby gem plus a `.ai/` control plane that adopters receive through `soft-foundry update`; nothing is deployed to a service and nothing is published to RubyGems. Order within the single change PR:

1. Code, templates, `workflow.yml` `isolated_phases`, harness evals, and docs merge together (the control plane and the CLI that reads it must move together, REQ-027). Implementation commits follow the slice order in `implementation.md` so each commit is green.
2. After merge to `main`, close this change's record (`change close`) so `ci` on `main` passes; this change does not use `released` for itself.
3. The maintainer builds and installs the gem locally under the asdf Ruby the global wrapper uses.
4. Adopters pick up the control plane with `soft-foundry update`. An adopter's older `workflow.yml` has no `isolated_phases`: nothing breaks, `--parallel` refuses with a message saying to add the list. Older records have no `phase_reopenings` or `release`: valid.

## Migrations and backfills
N/A. No existing record is rewritten. New keys are written only by the new commands.

## Feature flags and gradual exposure
None needed: every new behaviour is behind an explicit command or flag (`phase reopen`, `--parallel`, `change release`). The one automatic behaviour, auto-reopen of a stale complete phase in `phase run`, replaces a refusal that previously led people to hand-edit handoffs; it is recorded, labelled, and `--dry-run` previews it.

## Success signals to watch
- `soft-foundry check`, `ci`, the full suite (keys unset), and `soft-foundry eval` pass on the PR.
- After release, adopters stop hand-editing handoffs: no `sed` on `handoff.yml` in feedback; reopen history entries appear in `phase_reopenings` with reasons.
- Any merged record that is `released` shows its open items in `ci` output on `main` and is eventually closed (follow-up: look for long-lived released records at the next change; the memory note on un-closed records applies).
- No report of a corrupted `metadata.yml` or a lock timeout in normal use.
