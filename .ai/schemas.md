# Change Record Schemas

## `changes/<slug>/metadata.yml`

Created from `.ai/templates/change/metadata.yml`. `current_phase` is the lifecycle id of the phase currently being worked. `status: awaiting_human` marks a change parked on a human-boundary decision; the phase handoff records the decision requested.

`track` names the lifecycle track (`tracks:` in `.ai/workflow.yml`; a record without one is on the default). On a track with an exploring stage, `status: exploring` means the change is being iterated with a person: the stage's skill works in `changes/<slug>/<output>/` (its `iterations.yml` journal, one entry per round), the specification is a living draft, and no phase from `implement` onward may be `complete`. `soft-foundry change vet` writes `vetted: {at, by, commit}` and sets `status: in_progress`; from that commit `02-specification/` may not change (the gate's `specification locked` check; on the gated track the lock is the commit that recorded the completed specify phase instead) and the phases from `implement` onward apply as on the gated track. `status` is one of `intake`, `exploring`, `in_progress`, `awaiting_human`, `judged`, `released`, `closed`; `released` means finished and approved while owing the items in `release:`, and `closed` stays the only end state. `phase_reopenings` records each `phase reopen` or automatic reopen by `phase run`: `at`, `phase`, `reset` (phases returned to pending, evidence files kept), `from_commit`, `reason`, `source` (`manual` or `auto`), `previous` (the phase's prior status); `reopenings` keeps its meaning (return to exploring). `release` is `{at, commit, items: [{id, description, from?: judgment, discharged_at?, discharge_commit?, discharge_note?}]}` and must be non-empty on a released record. `phase run` sets `SOFT_FOUNDRY_PHASE=<phase id>` in every session (and `SOFT_FOUNDRY_PARALLEL=1` in a parallel run); the guard resolves the skill from it, and `phase reopen`, `change release` and `change discharge` refuse when it is present. That marker guards against accident and a prompt-following agent; it is not a sandbox, and a session that unsets the variable in a shell is not stopped by the tool. `soft-foundry change reopen` clears `vetted`, appends to `reopenings` (`at`, `from_commit`, `reason`), resets every phase from `implement` onward to `pending` with its files kept, and returns to `exploring`. A track's `optional` phases may stay `pending` without a `skipped_phases` rationale; `forced_by_risk` makes a declared `risk` select the track regardless of what `change new --track` asked.

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
| `panel` | Written only by `soft-foundry phase run --panel`: `members` (each `name`, `shell`, `provider`, `session_id`), `rounds`, `max_rounds`, `outcome` (`agreed` or `split`), `agreed` (the agreed sentence), `notes`. Present only when the phase ran as a panel. |
| `executed_by` | Written only by `soft-foundry phase run`: `runner`, `shell`, `fresh_context: true`, `started_at`, `finished_at`, `exit_status`, `previous_phase`, `session_id` (the coding session, chosen up front for Claude Code and Grok, taken from the session ledger for Codex, or null), and `cwd` (the folder it ran in, for resuming it). `null` when the phase was worked by whatever session was open. A review or judgment completed without it draws an advisory. |

`surfaces.accessibility: true` means a person perceives or operates the result (UI, CLI output, a document). `change new` sets it when `.ai/repository.yml` records a user-facing framework. It selects `.ai/rules/accessibility.md` for implementation and review, and enables the accessibility go-live advisories.

`surfaces.policy: true` means the change alters what the application collects, shares, retains, protects, or promises in its published privacy policy, security policy, or terms. `change new` sets it when `.ai/repository.yml` records a published policy document under `policies:`. It selects `.ai/rules/policy-conformance.md` for implementation and review, and enables the policy go-live advisories.

`scope` (optional) is a list of path globs the change owns; absent or empty means the whole repository. A record with a scope is stale only when a changed code file is inside its scope, inside the repository's `shared_core` (a list of globs in `.ai/repository.yml`), or claimed by no active record's scope; a code file inside another active record's scope does not stale it. Editing a record's `scope`, the profile's `shared_core` or `access_control`, or `.ai/policies/check-sizing.yml` after the evidence commit stales the evidence. A record without a scope behaves as before: any code change stales it.

`human_decisions` lists the human-boundary decisions (`.ai/policies/human-boundaries.yml`) the change required, each with `boundary`, `subject`, `decided_by`, `decided_at`, and `decision`. While a decision the review says is owed has no entry, the change is parked with `status: awaiting_human`; the phase handoff records what was asked.

## Gate semantics

`soft-foundry gate <phase>` evaluates a phase's handoff against `completion.yml`:

- `pending` phases are skipped.
- `in_progress` and `blocked` phases are reported but do not fail the gate.
- `complete` phases must have every required file present with no `TBD` placeholder remaining, a valid handoff, an empty `blocking` list, a recorded `commit_sha`, and a complete predecessor phase (stepping back over phases that are globally optional, waived in `skipped_phases` with a rationale, or not required by the change's track).
- Phases whose skill declares `evidence: commit_bound` are additionally `STALE` when any file in the `APP`, `TESTS`, or `INFRA` path groups changed between `commit_sha` and the current worktree, including uncommitted changes. When the record's `git.branch` is not the branch checked out and that branch still exists (locally or at `origin`), the measure is that branch's tip instead: a change stacked on another change's branch covers its own code with its own record, and the earlier record's claim is about the earlier branch. Once the branch is gone, or on the branch itself, the worktree is the measure. The same check also fails when the specification was re-recorded after the evidence: the commit that recorded the completed specify handoff (the lock) is not an ancestor of the commit that recorded this phase's completed handoff. Recorded in the same commit, or this phase recorded later, is current.
- The first phase carries a `track permitted` check: the change's track must be defined, must have an exploring stage if the change is `exploring`, and must be the one its declared `risk` forces.
- The first phase also carries a `waivers permitted` check: every entry in `skipped_phases` must name a lifecycle phase that is globally `optional` or listed for the change's declared `risk` in `.ai/workflow.yml` `waivable_by_risk` (matched case-insensitively); `review` and `judge` are never waivable; an unset, placeholder, or unknown risk waives nothing but optional phases. Structure only: the rationale text is not judged.
- While the change is `exploring`, a `complete` phase from `implement` onward fails its `not exploring` check; `change vet` is the way forward.
- The specification phase carries a `specification locked` check. After `change vet` it fails when anything under `02-specification/` changed since the vetted commit, including uncommitted edits. On every other track it fails when anything under `02-specification/` other than `handoff.yml` changed since the commit that recorded the completed specify handoff (the newest commit touching the handoff while it says `complete`); until that handoff is committed the check warns `not yet locked` and does not fail. A specification change after the lock is a recorded requirement change: rerun the specification phase (its handoff re-binds the lock), after which every commit-bound phase is stale (above).
- Every complete phase carries a `content clean` check over the files in its directory: invisible Unicode and secret-shaped strings fail it, instruction-override phrases and fetch-and-execute commands warn (a record may quote an attack it found), and `.ai/policies/content-scan.yml` or an in-line `soft-foundry:scan-allow` marker exempts all but invisible text.
- The review phase carries a `findings explained` check over its handoff's `findings`: every finding whose severity is not `minor` (blocking, major, or any other word, or none) needs a non-empty `failure:` (the concrete input or state and the wrong result it leads to). Structure only: the gate does not judge whether the failure is real. Minor findings need none.
- A phase whose handoff has a `panel:` block carries a `panel recorded` check: at least two members, a non-empty draft under `panel/<member>/` for each, a non-empty `panel/ARGUMENT.md`, an `outcome` of `agreed` or `split`, and every `panel/<member>/` path cited in the phase's own files.
- The learning phase carries an `instincts valid` check over `15-learning/instincts.yml`: every entry needs a kebab-case unique `id`, a `trigger`, an `action`, a numeric `confidence` in 0..1, and non-empty `evidence`; an empty list passes.
- The verification phase carries a `red evidence` check over the checks in `06-verification/tests.yml` that name a `red_commit` (optionally with `test_path`): each must be a commit that precedes `commit_sha`, hold the test file, and be followed by an `APP` or `INFRA` change before `commit_sha`. Checks without `red_commit` are skipped; the test is not re-run at the RED commit.
- The verification phase carries a `check size matches diff` check and a `full-suite run recorded (record check, not a test result)` check over `06-verification/tests.yml`. `size:` must be at least the size `soft-foundry change size --phase verify` computes from the diff, the declared `scope`, `shared_core`, and `.ai/policies/check-sizing.yml`. An optional `full_suite:` block records a run by the git tree hash of the evidence commit (`tree`, `command`, `outcome`), or cites another record's run with `cite: <slug>` for the same tree; a mismatched tree, a recorded outcome other than `passed`, or uncommitted code fails the check. A passing full-suite check shows that a recorded run names this tree with a recorded outcome, not that the suite passed; Soft Foundry never runs the application's tests.

A stale or failed gate must be resolved by rerunning the phase, never by editing the handoff.

## Go-live advisories

`soft-foundry gate`, `change status`, `ci`, and `change close` print an `advisory:` block after the gate results when something a person should know about before the change ships is missing. Advisories are informational: they never change the exit code or block a phase. Today they cover:

- the review or judge phase waived through `skipped_phases`, with the rationale given (the gate's `waivers permitted` check also fails such a record);
- every completed phase whose skill declares `evidence: commit_bound` (verification, evaluation, attack, review, judgment) whose handoff carries no `executed_by` with `fresh_context: true` from `soft-foundry phase run`: it was performed by whatever session was already open;
- a phase run as a panel whose members all ran on one provider;
- a completed review or judgment that ran on the same provider as a phase its skill names in `prefer_different_provider_from` (`implement` and `remediate` for both): the provider is the handoff's `resolved_model.provider`, else the shell in `executed_by`;
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

## Harness eval cases

`.ai/harness-evals/cases/<id>.yml`, one case per file, run by `soft-foundry eval` and linted by `soft-foundry check` (`.ai/harness-evals/README.md` has the full format). Fields:

| Field | Rule |
| --- | --- |
| `id` | Equal to the file name without `.yml`. |
| `kind` | `gate` (plant a record, assert a gate check) or `live` (plant application files and a record, run a phase in a fresh session, assert a finding). |
| `description` | Non-empty; printed by `eval` with the outcome. |
| `phase` | Live cases only: the lifecycle phase `phase run` executes. |
| `record` | `risk` (default `low`), optional `track` and `status`, `complete` (phases recorded complete at the bound commit, templates filled), `skipped` (phases named in `skipped_phases` with a supplied rationale), `handoff` (keys merged into a phase's handoff), `files` (written into the record before its commit), `commit` (`false` leaves the record uncommitted), `later_files` (written after the commit), `scope` (path globs for the record's `scope`), `siblings` (other active records, each `slug` and `scope`). A top-level `profile` mapping declares repository keys such as `shared_core` and `access_control` in the scratch `.ai/repository.yml`. |
| `repository` | `files` written into the scratch repository after the record is complete; `commit: true` commits them. |
| `application` | Live cases: `files` written and committed before the record exists. |
| `expect` | Gate: `phase`, `outcome` (`pass` or `fail`), optional `check` naming a gate check (without it the whole phase's outcome is compared). Live: `finding`, a regular expression over the phase's handoff findings (`summary`, `failure`, `id`) and its Markdown files. |

File paths are relative, inside the tree, never traverse upward, and number at most 200 per case. Contents may carry `${COMMIT}` (the bound commit), `${APP_FILE}` (a code file in the `APP` group, also valid as a path), `${CANARY_AWS}`, `${CANARY_OPENAI}`, and `${INVISIBLE_ZWSP}` (secret-shaped and invisible canaries the runner builds). `eval --json` prints `{"version": 1, "stable": false, "results": [...], "summary": {...}}`; each result carries `id`, `kind`, `outcome` (`pass`, `fail`, `error`, `skip`), `detail`, `phase`, `check`, `expected`, `observed`, and for live cases `shell`, `model`, and `matched`.
