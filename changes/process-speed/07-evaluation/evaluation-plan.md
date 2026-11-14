# Evaluation Plan

Commit evaluated: 0c213b4c26aca56a5a4f686bfc4ebf0018be4297 (`Record process-speed verify`). Its code is identical to the implementation commit a37d580. The commits after a37d580 change the record only.

Size: `full_route_sweep`. `soft-foundry change size --phase evaluate` reports "no scope declared: whole-repository scope is sized at the largest size". Soft Foundry has no web UI routes, so for this command-line tool "every route" means every command the change touches. Those are `change new`, `gate` (specify, verify, review, judge, intake and the waivers check), `phase reopen` (with and without `--docs-only`), `phase seal remediate`, `phase run` (parked change and automatic reopen), `change release`, `change size`, `change status` (text and `--json`), `check` and `help`. A smoke run of `check` against the branch's own control plane is included.

## Intent being proven
The lifecycle converges, as the specification says. A person approves the must criteria before the specification seals. Remediation stops after two sealed rounds until a person decides. Only must criteria and blocking in-change findings can block. Person-only checks become release items. Out-of-change findings become follow-ups. The loop gets lighter for low-risk and documentation-only work. Records created before this change behave exactly as before.

## Personas
- **Maintainer (person):** runs the change from a terminal. Records `human_decisions` (the must-list approval and the remediation-cap answer), reopens phases, seals and releases. All journeys run with `SOFT_FOUNDRY_PHASE` unset, as a person's shell would have it.
- **Phase-run session:** the runner starting a fresh session. It is exercised by `phase run` on a parked change and on a stale phase at the cap. A stand-in `claude` on PATH records whether a session would have started.
- **Legacy record owner:** a record created before the convergence rules (no `rules: 2`).

## Journeys
Each journey runs the real CLI from this worktree (`ruby -I<worktree>/lib <worktree>/exe/soft-foundry`, Ruby 3.3.1, `NO_COLOR=1`) against a throwaway git repository under `/tmp`. Each repository carries a copy of the branch's `.ai/`. Records were created by `change new`. Phases the journey does not exercise were filled with the shipped `SoftFoundry::HarnessEval.complete_phase!`, the same filler the harness evals use. `evidence/tools/` holds the two scripts. The journeys run real `phase seal`, `phase reopen`, `phase run` and `change release` commands. Seal commits come from `phase seal` itself and are never hand-written.

The EVAL IDs, criteria, starting state, steps, assertions, evidence and result for each journey are in `journeys.yml`. The must criteria the person approved (AC-001, 002, 004, 005, 006, 007, 008, 009, 010, 015, 017, 018) come first. The should criteria AC-003, 011, 012, 013, 014 and 019 are covered as size allows. AC-016 (skill text), AC-017 (CHECKS and eval coverage) and AC-018 (full suite and `ci`) are repository inspections, not user journeys. Verification owns them (CHECK-001, 005, 007, 008), so they are mapped to that evidence and not re-run here.

## UI walkthrough evidence
No graphical UI changed. The command-line transcripts in `evidence/` are the walkthrough. They are captured at each state transition: refusal, parked status, decision recorded, round permitted, seal refused or allowed, release written.

## Accessibility interaction
`surfaces.accessibility` is true because the change adds command-line refusals, warnings and advisories. What was exercised:
- **Keyboard-only operation:** every journey is typed commands with no prompts, pointer or TTY interaction.
- **Colour independence:** every run had `NO_COLOR=1`, and the transcripts contain no escape sequences.
- **Non-ASCII stripped:** across every captured line, the only non-ASCII characters are the existing check glyphs (✓ ✗). With those stripped, the outcome word (`pass`, `fail`, `warn`, `skip`), the prefix (`soft-foundry:`, `<slug>:`, `phase reopen:`) and the next action survive (AC-019).
- **Error identification:** each refusal names what failed (criterion ids, round count, path) and the action a person takes.
- **Screen-reader readable output:** everything is plain text. Very long single-line refusals are noted as advisory.
