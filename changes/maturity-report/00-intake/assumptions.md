# Assumptions

## Explicit assumptions
- "Blocking the next level" means exactly `.ai/repository.yml`'s existing `maturity.gaps` list; no new scoring logic.
- "Other recorded deficiencies" means every non-satisfied capability not already in that gaps list — real findings that don't gate the current score (a conditional signal, or a requirement of a level further out) but are worth surfacing.
- The report file lives under `.ai/` (not a change record), matching where `.ai/repository.yml` itself lives: repository-level state, not change-scoped.
- Given this change's scope, it receives the same lighter-weight process as the prior three small CLI additions to this repository: implemented and tested directly, with real verification.

## Ambiguities resolved
- Whether the report should be gitignored or committed: committed, since its source (`.ai/repository.yml`) is itself durable, evidence-backed, committed state; the report should be too, so it's visible to teammates and future sessions.

## Ambiguities that block safe progress
None.
