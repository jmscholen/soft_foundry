# Rollback

## Trigger conditions
- A published 0.2.0 produces exit 4 on a supported platform.
- A maintainer reports user content overwritten without `--force`.
- The manifest scheme proves incompatible with a common workflow (for example autocrlf) and cannot be patched quickly.

## Procedure
- Gem: yank 0.2.0 or publish 0.2.1 with `init` reverted to the 0.1.0 alias behavior; the installer classes can remain unused.
- Target repository: `init` never deletes, so every effect is a create or an in-place write to a managed path. Restore with `git checkout -- .ai AGENTS.md CLAUDE.md .gitignore changes/README.md docs/user/README.md` and remove `.ai/manifest.yml` and any newly created files listed as `created` in the report. `--dry-run` output from before the run is the exact list.

## Data considerations
No databases. `.soft-foundry/runtime.yml` is machine-local and gitignored; removing it is harmless.

## Time to recover
Under five minutes for a target repository; one gem publish cycle for the package.
