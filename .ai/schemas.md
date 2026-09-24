# Change Record Schemas

## `changes/<slug>/metadata.yml`

Created from `.ai/templates/change/metadata.yml`. `current_phase` is the lifecycle id of the phase currently being worked. `status: awaiting_human` marks a change parked on a human-boundary decision; the phase handoff records the decision requested.

`track` names the lifecycle track (`tracks:` in `.ai/workflow.yml`; a record without one is on the default). On a track with an exploring stage, `status: exploring` means the change is being iterated with a person: the stage's skill works in `changes/<slug>/<output>/` (its `iterations.yml` journal, one entry per round), the specification is a living draft, and no phase from `implement` onward may be `complete`. `soft-foundry change vet` writes `vetted: {at, by, commit}` and sets `status: in_progress`; from that commit `02-specification/` may not change (the gate's `specification locked` check) and the phases from `implement` onward apply as on the gated track. `soft-foundry change reopen` clears `vetted`, appends to `reopenings` (`at`, `from_commit`, `reason`), resets every phase from `implement` onward to `pending` with its files kept, and returns to `exploring`. A track's `optional` phases may stay `pending` without a `skipped_phases` rationale; `forced_by_risk` makes a declared `risk` select the track regardless of what `change new --track` asked.

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
| `executed_by` | Written only by `soft-foundry phase run`: `runner`, `shell`, `fresh_context: true`, `started_at`, `finished_at`, `exit_status`, `previous_phase`. `null` when the phase was worked by whatever session was open. A review or judgment completed without it draws an advisory. |

`surfaces.accessibility: true` means a person perceives or operates the result (UI, CLI output, a document). `change new` sets it when `.ai/repository.yml` records a user-facing framework. It selects `.ai/rules/accessibility.md` for implementation and review, and enables the accessibility go-live advisories.

`surfaces.policy: true` means the change alters what the application collects, shares, retains, protects, or promises in its published privacy policy, security policy, or terms. `change new` sets it when `.ai/repository.yml` records a published policy document under `policies:`. It selects `.ai/rules/policy-conformance.md` for implementation and review, and enables the policy go-live advisories.

`human_decisions` lists the human-boundary decisions (`.ai/policies/human-boundaries.yml`) the change required, each with `boundary`, `subject`, `decided_by`, `decided_at`, and `decision`. While a decision the review says is owed has no entry, the change is parked with `status: awaiting_human`; the phase handoff records what was asked.

## Gate semantics

`soft-foundry gate <phase>` evaluates a phase's handoff against `completion.yml`:

- `pending` phases are skipped.
- `in_progress` and `blocked` phases are reported but do not fail the gate.
- `complete` phases must have every required file present with no `TBD` placeholder remaining, a valid handoff, an empty `blocking` list, a recorded `commit_sha`, and a complete predecessor phase (stepping back over phases that are globally optional, waived in `skipped_phases` with a rationale, or not required by the change's track).
- Phases whose skill declares `evidence: commit_bound` are additionally `STALE` when any file in the `APP`, `TESTS`, or `INFRA` path groups changed between `commit_sha` and the current worktree, including uncommitted changes. When the record's `git.branch` is not the branch checked out and that branch still exists (locally or at `origin`), the measure is that branch's tip instead: a change stacked on another change's branch covers its own code with its own record, and the earlier record's claim is about the earlier branch. Once the branch is gone, or on the branch itself, the worktree is the measure.
- The first phase carries a `track permitted` check: the change's track must be defined, must have an exploring stage if the change is `exploring`, and must be the one its declared `risk` forces.
- While the change is `exploring`, a `complete` phase from `implement` onward fails its `not exploring` check; `change vet` is the way forward.
- After `change vet`, the specification phase carries a `specification locked` check that fails when anything under `02-specification/` changed since the vetted commit, including uncommitted edits.
- The learning phase carries an `instincts valid` check over `15-learning/instincts.yml`: every entry needs a kebab-case unique `id`, a `trigger`, an `action`, a numeric `confidence` in 0..1, and non-empty `evidence`; an empty list passes.
- The verification phase carries a `red evidence` check over the checks in `06-verification/tests.yml` that name a `red_commit` (optionally with `test_path`): each must be a commit that precedes `commit_sha`, hold the test file, and be followed by an `APP` or `INFRA` change before `commit_sha`. Checks without `red_commit` are skipped; the test is not re-run at the RED commit.

A stale or failed gate must be resolved by rerunning the phase, never by editing the handoff.

## Go-live advisories

`soft-foundry gate`, `change status`, `ci`, and `change close` print an `advisory:` block after the gate results when something a person should know about before the change ships is missing. Advisories are informational: they never change the exit code or block a phase. Today they cover:

- the review or judge phase waived through `skipped_phases`, with the rationale given;
- a feature, fix, or refactor whose completed verification has no check naming a `red_commit` (no failing-test-first evidence);
- a change on a track with an exploring stage in a repository whose profile records no `development` environment under `environments:` (`NOT_APPLICABLE` with a rationale is a valid answer);
- a change that declares `surfaces.accessibility: true` but has no `category: accessibility` requirement, no accessibility observations in evaluation, or an accessibility review that is pending, skipped, still TBD, or N/A;
- a change that declares `surfaces.accessibility: false` in a repository whose profile records a user-facing framework;
- a repository with no `.ai/rules/accessibility.md` in force;
- a change that declares `surfaces.policy: true` but has no `category: policy` requirement, or a policy-conformance review that is pending, skipped, still TBD, or N/A, or a repository profile that records no published policy document to check against;
- a policy-conformance review that lists policy text changes owed with no matching `human_decisions` entry (a legal commitment awaiting a person);
- a change that declares `surfaces.policy: false` in a repository whose profile records a published policy document;
- a repository with no `.ai/rules/policy-conformance.md` in force.

Every advisory line starts with `! warn` and the area (`accessibility`, `policy`, `review`, `judgment`) so it can be searched for in a log.
