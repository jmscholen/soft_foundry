# Owed: control plane, documentation, and harness evals

The implementation skill may not write `.ai/**`, `docs/**`, the harness evals, or the repository `README.md`, so these edits (deviation D1) are for a maintainer. The code is complete and reads the declarations below. Until the first one lands, `phase run ... --parallel` refuses with "no isolated_phases declared in .ai/workflow.yml".

## `.ai/workflow.yml`
Add beside `panel_phases`:

```yaml
# Phases that write only their own directory and may run side by side with
# `soft-foundry phase run <phase> <phase> --parallel`. `check` refuses
# implement, remediate, review, judge, or any phase whose skill can write
# application code.
isolated_phases: [evaluate, attack]
```

## `.ai/templates/change/metadata.yml`
- `phase_reopenings: []` next to `reopenings:`, with a comment: one entry per `phase reopen` or automatic reopen (at, phase, reset, from_commit, reason, source manual|auto, previous).
- In the status vocabulary comment add `released` (finished and approved, owing the items in `release:`; `closed` stays the only end state).
- An absent `release:` key is valid; do not add an empty one (a released record needs a non-empty block).

## `.ai/schemas.md`
- Status vocabulary: add `released`.
- `phase_reopenings` entry shape (above) and that `reopenings` keeps its meaning (return to exploring).
- `release` block: `at`, `commit`, `items: [{id, description, from?: judgment, discharged_at?, discharge_commit?, discharge_note?}]`.
- The session marker: `SOFT_FOUNDRY_PHASE=<phase id>` set by `phase run` in every session (and `SOFT_FOUNDRY_PARALLEL=1` in a parallel run); the guard resolves the skill from it; `phase reopen`, `change release`, `change discharge` refuse when it is present. State plainly that it is a guard against accident and a prompt-following agent, not a sandbox: a session that unsets the variable in a shell is not stopped by the tool.

## `.ai/README.md`
- Layout table, `workflow.yml` row: mention `isolated_phases`.
- A short section naming `phase reopen`, `phase run ... --parallel [--env]`, and `change release` / `change discharge`; and that `check` lints `isolated_phases` and the release block.

## `.ai/harness-evals/cases/`
Follow the format of the existing cases (this phase could not read them):
1. a gate case that plants a record with `status: released` and a missing, empty, or malformed `release` block and names the check that must refuse it (the `check` lint: "released record's release block is missing" / "no items" / "duplicate id");
2. a gate case that plants a non-isolated parallel request (for example `verify` with `evaluate`) and expects the refusal "not in isolated_phases";
3. a live case: a complete phase made stale by a planted code change, run through `phase run`, expecting an automatic reopen recorded in `phase_reopenings` with `source: auto`.
`STATUSES` in `lib/soft_foundry/harness_eval.rb` already admits `released`.

## `README.md` and `docs/user/`
Use a real heading hierarchy and descriptive link text.
- `phase reopen <phase> --reason TEXT`: what is reset (the phase, later phases, and the `next` loop-back of the reopened phase), that evidence files are kept, the `phase_reopenings` history, the automatic reopen in `phase run`, and refusals (closed, released, exploring, awaiting_human, nothing to reset, inside a phase-run session).
- `phase run A B --parallel [--env NAME=VALUE]...`: only `isolated_phases`; each session gets its own `{phase}`-expanded value; Soft Foundry never creates or tears down what a value names (isolating a shared database, port or cache is the adopter's responsibility; the run prints a `warn:` line when no `--env` is given); sessions are told not to commit and share the start HEAD; the `--env` value exposure note (it is in the child's environment, never in files, output, or argv; the person's shell history and a microsecond window before the process title is rewritten remain); the output lines `phase <id>: pass|fail` and `parallel:`.
- `change release --item ID=DESCRIPTION` / `change discharge ID --note TEXT` / `change close` on a released record, how `ci` treats a merged released change (passes while items are open and lists them), and that `closed` remains the only end state.
- The session-marker residual described under `.ai/schemas.md`.
