# Consolidated Review

Commit reviewed: `276dc8d611cbf6ae2456ea99061cd7ce9ba9932c`. The code is unchanged since `03a184b`, the commit the verification evidence describes. Rules loaded: `.ai/rules/accessibility.md`, `.ai/rules/policy-conformance.md`, `.ai/rules/rails.md` (read as changed content, not applied; this repository is not Rails), `.ai/rules/infrastructure.md` (nothing to apply).

Code-quality phase: did not run for this change. The record carries `rules: 2`, which predates the phase; it is on the light track, where the phase is optional; and this repository's profile sets `quality_gate.enabled: false`. Design, duplication and clarity are covered in `architecture.md` and `functional.md`.

## Functional
Does not conform. REV-001 (blocking): `soft-foundry init` leaves `quality_gate.enabled: false` in a Ruby repository. The template's `set_by: null` reads to the scan as a person's choice, so onboarding never turns the gate on in a new install. Reproduced on a scratch repository. Everything else in REQ-001 to REQ-014 is met as far as this reading and the 27 passing tests go. REV-002 (AC-008 structural only) and REV-003 (rules-number assertion) are minor.

## Architecture
Conforms with minors. The data-driven applicability and `CURRENT` alongside `VERSION` are sound. REV-004: the UI's separate `skip_reason` gives no reason for a not-asked phase. REV-005: check lists are duplicated between `checks_for` and `evaluate`.

## Security
Conforms. The quality phase writes only its own directory and cannot read harness evals (AC-004 tested). REV-006 (outside this change): the guard's after-hook writes stray policy copies when the shell's working directory is a subdirectory.

## Accessibility
Conforms. Status reasons, gate messages, help and the user page are plain words with structured headings, lists and tables.

## Policy conformance
N/A. Nothing collected, shared, retained, protected or promised changes. No policy text change is owed.

## Infrastructure
N/A. No infrastructure is present or modified.

## Operations
Conforms with minors. REV-007: no harness eval case for the new check. REV-008: the installed binary predates the branch, so gate with the worktree's `lib/`.

## Blocking findings
- REV-001 (`unmet_need`-shaped; functional): onboarding never enables the gate in a newly initialized repository. Remedy: let the scan replace a value whose `set_by` is blank, or remove the block from the template. Then add a test that runs `init` on a Ruby fixture. Goes to remediation, then verify and review again.

## Residual concerns
- AC-008 is covered structurally only (VER-001, REV-002).
- Two untracked files left by the guard hook in this session, `.ai/skills/review/.ai/policies/enforcement.yml` and `changes/code-quality-gate/.ai/policies/enforcement.yml`, need to be deleted by the maintainer before anything is committed with `git add -A`.
