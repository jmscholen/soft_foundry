# Change Provenance

Every engineering change receives a durable `changes/<change-slug>/` record created by `soft-foundry change new <slug>` from `.ai/templates/` and every applicable `.ai/skills/*/template/`. The Git worktree is disposable execution space; this directory is durable provenance.

A change record preserves phase handoffs, failures, evidence, remediations, documentation changes, final judgment, and learning. The slug matches the change's branch name. Schemas are described in `.ai/schemas.md`; `soft-foundry change status` and `soft-foundry gate` report the record's state.
