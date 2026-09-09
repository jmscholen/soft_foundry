# Change Provenance

Every engineering change receives a durable `changes/<change-slug>/` record initialized from all applicable `.ai/skills/*/template/` files. The Git worktree is disposable execution space; this directory is durable provenance.

A change record must preserve phase handoffs, failures, evidence, remediations, documentation changes, final judgment, and learning. Prefer a stable change ID plus readable worktree slug in metadata.
