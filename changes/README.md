# Change Provenance

This directory is Soft Foundry's own audit log. Product code is `lib/` and
`exe/`. The control plane shipped to adopters is `.ai/`. A five-minute
picture of the loop an application repository should learn first is
`examples/tiny-app/`, not the records here.

Every engineering change receives a durable `changes/<change-slug>/` record created by `soft-foundry change new <slug>` from `.ai/templates/` and every applicable `.ai/skills/*/template/`. The Git worktree is disposable execution space; this directory is durable provenance.

A change record preserves phase handoffs, failures, evidence, remediations, documentation changes, final judgment, and learning. The slug matches the change's branch name. Schemas are described in `.ai/schemas.md`; `soft-foundry change status` and `soft-foundry gate` report the record's state.

Do not write machine-local absolute worktree paths into `metadata.yml`.
`change new` records `git.worktree: "."`.
