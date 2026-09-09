# Rollout

## Deployment ordering
1. Land steps 1 to 5 (errors, gemspec, template, manifest, source, installer plan and apply) with their unit tests. No user-visible change.
2. Land steps 6 to 8 (pointer files, onboarding, CLI, doctor, check). `init` changes meaning from an `onboard` alias to a real install.
3. Land step 9 (docs, version 0.2.0) and build the gem.
4. Tag and publish 0.2.0 after final judgment.

## Migrations and backfills
- Repositories onboarded by 0.1.0 have `CLAUDE.md` with the single legacy marker and no manifest. First `init` run recognizes the legacy block as complete, installs `.ai/` fresh, and writes the manifest. No data migration.
- Repositories that hand-copied `.ai/` (including this one) get identical files `skipped` and adopted into the manifest, differing files `conflict`. Maintainers resolve conflicts once, then runs are clean.

## Feature flags and gradual exposure
None. `--dry-run` is the preview mechanism.

## Success signals to watch
- `soft-foundry check` passes on every freshly initialized fixture in CI.
- Second-run reports are all `skipped` in the AC-003 test and in a manual run on a real application repository before publishing.
- No exit code 4 in CI or manual runs; any occurrence is by definition a Soft Foundry defect and blocks release.
