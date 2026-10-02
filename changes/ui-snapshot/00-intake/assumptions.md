# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase. Review is therefore not independent, and the advisory says so on every gate run.
- The plan the maintainer approved (three stacked changes, hand-rolled loopback server later, read-only) is the plan record; this change's part of it is restated in `05-implementation/log.md`.
- Discovery-shaped facts were read from the code before planning: `Gate::Result`/`Check`, `Advisory::Notice`, `Budget::Entry`/`Totals`, and `ControlPlane::Phase`/`Track` already exist as data objects; nothing serialised them; `list_changes`, `load_record`, and the merged-not-closed test were private to the CLI.
- Gating every record costs about 0.4 s each on this repository (git subprocesses), about 8 s for all twenty. Closed records are therefore not gated on the board, matching what `ci` already does.
- Threats reasoned through here in place of the skipped threat-model phase: (1) a record with malformed YAML or wrong-typed fields must not take down the board: each row is rescued and reported; (2) error messages from YAML name absolute paths: they are made repository-relative; (3) `git.worktree` is an absolute local path and is omitted; (4) strings are forced to valid UTF-8 before serialising, though YAML already refuses a non-UTF-8 file; (5) JSON output is data, and escaping it for a page is the page's job (the next change sets text with `textContent` only).

## Ambiguities resolved
- Where to describe "what each gate checks": next to the gate (`Gate::CHECKS`, `Gate.checks_for`), so the description cannot drift into a second file, with a test that the list covers what the gate really runs.
- Whether a closed record's detail is gated: yes, on request (`change status <slug> --json`), as the text form already does. Only the board skips closed records.
- Which commands get `--json`: the two that map to the two views (board, one change). Others wait for a need.

## Ambiguities that block safe progress
None.
