# Change Record Schemas

## `changes/<slug>/metadata.yml`

Created from `.ai/templates/change/metadata.yml`. `current_phase` is the lifecycle id of the phase currently being worked. `status: awaiting_human` marks a change parked on a human-boundary decision; the phase handoff records the decision requested.

## `changes/<slug>/<phase>/handoff.yml`

Created from `.ai/templates/handoff.yml`. Field semantics:

| Field | Rule |
| --- | --- |
| `phase` | Must equal the phase directory name. |
| `skill` | Must equal the skill that owns the phase. |
| `status` | `pending`, `in_progress`, `complete`, or `blocked`. |
| `commit_sha` | Required when `complete`. HEAD of the worktree when the outputs were produced. |
| `completed_at` | Required when `complete`. ISO 8601. |
| `resolved_model` | Profile requested plus the provider/model actually used. |
| `outputs` | Files produced by the phase. |
| `blocking` | Must be empty when `complete`. Non-empty forces `blocked`. |
| `findings` | Items handed to downstream phases. Each has `id`, `severity`, `summary`. |
| `next` | Lifecycle id the workflow proceeds to. |

## Gate semantics

`soft-foundry gate <phase>` evaluates a phase's handoff against `completion.yml`:

- `pending` phases are skipped.
- `in_progress` and `blocked` phases are reported but do not fail the gate.
- `complete` phases must have every required file present with no `TBD` placeholder remaining, a valid handoff, an empty `blocking` list, a recorded `commit_sha`, and a complete predecessor phase.
- Phases whose skill declares `evidence: commit_bound` are additionally `STALE` when any file in the `APP`, `TESTS`, or `INFRA` path groups changed between `commit_sha` and the current worktree, including uncommitted changes.

A stale or failed gate must be resolved by rerunning the phase, never by editing the handoff.
