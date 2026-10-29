# Rollout

## Deployment ordering
1. Merge the change branch to `main` after judgment; close the record.
2. Build and install the gem locally under the asdf Ruby the global wrapper uses (this repository never publishes to RubyGems).
3. Adopter repositories receive the new gate and command through `soft-foundry update` (control plane) and their local gem install; the control-plane files this change touches (templates, skill text, AGENTS.md block, harness-eval cases, learned rules) arrive with `init`/`update` as manifest-owned files.

## Migrations and backfills
N/A for data. For records: an adopter's in-flight record with a phase complete on disk but not committed fails its next gate's `predecessor complete` with the detail naming `soft-foundry phase seal <phase>`; running it is the migration. Closed and released records are untouched by every new check.

## Feature flags and gradual exposure
None. The checks are the gate. The one conditional is `fresh session recorded`, which follows the repository's own `enforcement.yml` mode, so a repository in warn mode sees no new failure from it.

## Success signals to watch
- `soft-foundry ci` green on `main` after merge with every existing record.
- The first adopter change after the update: every phase shows a `Record <slug> <phase>` commit made by the tool, and no phase was committed by hand.
- `gate` output on an adopter's verify phase shows `test results recorded`, `criteria covered`, and `evidence manifest verified` with real details rather than skips.
- Hook time per seal stays within the bound evaluation recorded.
