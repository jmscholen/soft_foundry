# Assumptions

## Explicit assumptions
- "Existing Git repository" means a directory where `git rev-parse --is-inside-work-tree` succeeds; the repository root is the install target.
- "Idempotent" means a second run on an unchanged target reports every file as skipped and produces no diff.
- A `.ai/` file that differs from the packaged canonical version and is not marked as user-owned is a conflict, reported and left untouched by default.
- `changes/` scaffolding means `changes/README.md` only; individual change records are created by `soft-foundry change new`.
- `docs/user/` scaffolding is created only when the target has no `docs/` directory or already has `docs/user/`.
- The existing `onboard` behavior (provider discovery, `CLAUDE.md` pointer) remains available and `init` composes it rather than replacing it.

## Required test matrix
- installation into a clean Git repository
- an existing `AGENTS.md`
- an existing `CLAUDE.md`
- repeated initialization
- conflicting `.ai/` content
- `.gitignore` behavior
- preservation of unrelated application files
- refusal outside a Git repository

## Ambiguities resolved
- Whether `init` and `onboard` are the same command: they are not. `init` installs files; `onboard` discovers runtime. `init` runs onboarding at the end.
- Whether `.ai/repository.yml` is installed: yes, as the unassessed template, since discovery populates it later.

## Ambiguities that block safe progress
None. The conflict strategy default (report, do not overwrite) is conservative enough to proceed; an opt-in overwrite flag can be specified in the specification phase.
