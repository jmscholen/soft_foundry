# Rollout

## Deployment ordering
1. Merge to `main`; tag `v0.21.0`; the release workflow builds the gem.
2. Application repositories: `soft-foundry update --yes`, then `soft-foundry init` (the installer reports conflicts on `.ai/` files a repository changed; `enforcement.yml` and `workflow.yml` are the ones that change here), then `soft-foundry doctor` (mode line), then `soft-foundry eval`.
3. This repository: after merge, `change close factory-readiness` (which now requires the judgment this record has), and the next change runs under block mode with the override recorded when it needs the control plane.

## Migrations and backfills
N/A. Closed records are not gated and are not touched. Open records in any repository that waive judge or review, or waive beyond their risk, fail `ci` after the update until the waiver is removed; that is the intended effect and the failure line says which phase.

## Feature flags and gradual exposure
`SOFT_FOUNDRY_GUARD=warn` or the machine-local override returns a machine to the old mode without changing policy. Live evals are opt-in (`--live`).

## Success signals to watch
- `soft-foundry eval` exits 0 in this repository and in the Rails fixture.
- `ci` on `main` is green with the evals included.
- The next change's gate output shows `waivers permitted` and `specification locked` passing, and the fresh-context advisory naming any in-session evidence phase.
- The guard log shows refusals, not warnings, on a block-mode machine.
