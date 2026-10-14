# Assumptions

## Explicit assumptions
- "Finished and predictable state to run on application repos" means: an application repository that runs `soft-foundry init` gets a control plane whose gate, guard, and eval suite behave the same way they do here, with the guard refusing rather than warning, and the maintainer can prove that with one command. It does not mean every maturity level is reached; Level 6 needs the eval suite this change adds, and Level 7's remaining gaps (`learning.regression_creation`, `learning.workflow_feedback`) stay recorded as MISSING.
- A harness eval that plants a defective record and asserts the gate refuses it is the honest first measurement of the pipeline's discriminative power. It measures the gate, not a model. A live eval that plants a defect in an application and runs a fresh-context review measures a reviewer on one shell; its result is recorded with the shell and model that ran it and is not a benchmark score.
- The `claude` shell in this environment (Claude Code 2.1.299) runs headless prompts; `phase run --shell claude` therefore works here, on the same provider as implementation. That is a process boundary, not provider diversity, and the same-provider advisory will say so.
- Flipping `.ai/policies/enforcement.yml` to `block` is the right default for application repositories, where nothing an implementing agent should do touches `.ai/`. In this repository, where the control plane is the product, the maintainer uses the documented machine-local override when a change must edit it, and the change records the edit as a deviation.
- The Rails-shaped fixture (a `Gemfile` naming `rails`, `config/application.rb`, `app/`, `db/`, `spec/`) is enough for the control plane: the maturity scan, path groups, surfaces, and guard decide on file presence and paths, not on a booting Rails process. A real Rails application is the next proof and is out of scope here.

## Ambiguities resolved
- Which phases the fresh-context advisory covers: every phase whose skill declares `evidence: commit_bound` (verification, evaluation, attack, review, judgment). Data-driven from `skill.yml`, so a control plane that adds a commit-bound phase gets the advisory without a code change.
- What locks the specification on the gated track: the specify phase's own `commit_sha`. The check is the existing `specification locked` check, which on this track reads that commit instead of the vetted one. A specification change after lock is a recorded requirement change: the specify phase is rerun (its handoff re-binds), and every commit-bound phase completed before the change is stale, because its evidence was about the old criteria.
- Where eval results go: to the terminal and, with `--json`, to stdout. Nothing is written into a change record or `.ai/`; a live eval's shell and model are printed with its outcome.
- What `ci` runs: the deterministic (`gate`) evals only. Live evals need a shell and a model and are run on request.

## Ambiguities that block safe progress
None.
