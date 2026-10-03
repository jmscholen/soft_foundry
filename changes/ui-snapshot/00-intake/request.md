# Change Intake

## User intent
"I want to review this repo and add a user interface to better understand each gate visually and understand what is going on. Evaluate what we can do to make this a browser based tool or add an browser interface for what is going on in the cli." The maintainer then chose a live local server, read-only, with four views (change pipeline, all-changes board, workflow explainer, timeline and spend), and approved a plan in three stacked changes. This is the first: the data the views need, with no browser code.

## Desired outcome
Everything `change status`, `gate`, and `ci` know about the workflow and about each change is available as plain data, and as JSON from the CLI, without parsing terminal text.

- REQ-SNAP-001: one class (`ChangeIndex`) lists change records, loads one, and decides "merged but not closed"; `ci`, `change list`, and every command that loads a record use it. Text output and exit codes do not change.
- REQ-SNAP-002: `Snapshot#workflow` describes the lifecycle: each phase with its skill, output, optional/after, hardening flag, next phase, required files, commit binding, and the checks its gate runs with a one-line description each; transitions; judgments; tracks, the default, and `forced_by_risk`.
- REQ-SNAP-003: `Snapshot#board` has one row per change with one cell per phase. Records that are not closed are gated; closed records report their recorded handoff status and are marked not evaluated. A record that cannot be read gets a row carrying the error, and the rest still load.
- REQ-SNAP-004: `Snapshot#change` reports every gate with its status, a one-word state (pass, warn, fail, stale, in_progress, blocked, pending, missing), each check's name, outcome, and detail, why a pending phase may stay pending (waived with its rationale, track, optional), the track state as data, advisories, undischarged items, and whether it is merged but not closed.
- REQ-SNAP-005: `Snapshot#change` carries a timeline built only from recorded times (created, phase started and completed, iterations, vet, reopenings, human decisions, spend entries), oldest first, and the spend ledger with totals, per-phase sums, and the policy caps for the change's risk.
- REQ-SNAP-006: everything a snapshot returns survives a JSON round trip unchanged; timestamps are ISO-8601 strings; no absolute local path (including `git.worktree`) and no file content is included.
- REQ-SNAP-007: `change list --json` prints the board and `change status [slug] --json` prints the change, with the exit codes the text forms have (a failing gate is still 2, an unknown slug still 1). Help names both flags.

## Constraints
- No new runtime dependency; `json` is standard library and already used.
- `.ai/rules/architecture.md`: the snapshot must not depend on a delivery mechanism. It knows nothing of HTTP or of the CLI; the CLI calls it.
- `.ai/rules/security.md`: change records are input an attacker may have written. The snapshot must not fail the whole board on one bad record and must not leak local paths.
- Existing text output is a contract for people and CI logs; it must be byte-identical for `change status`, `change list`, and `ci`.

## Non-goals
- No server, HTML, or browser code (changes `ui-server` and `ui-explainer-timeline`).
- No `--json` on `gate`, `ci`, `doctor`, `check`, or `budget`.
- No new recorded fields: no `closed_at`, no event log, no git-history timeline.
- The JSON shape carries `version: 1` and is not yet a stable public contract.

## Task classification
feature

## Initial risk
low. Read-only additions; the one behavioural refactor (`ci` and record loading through `ChangeIndex`) is covered by the existing suite and by a byte-for-byte comparison against `main` in evaluation.
