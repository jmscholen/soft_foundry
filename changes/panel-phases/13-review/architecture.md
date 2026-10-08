# Architecture Review

## Scope reviewed

`Panel` against `PhaseRunner` and `Guard`, the `panel_phases` workflow key, `Gate.checks_for` versus `Gate#evaluate`, fingerprint scope, and the decisions in `05-implementation/decisions.md`. Rules loaded, the same baseline implementation is held to: `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, `.ai/rules/errors.md`, `.ai/rules/git.md`, `.ai/rules/testing.md`, `.ai/rules/security.md`, `.ai/rules/learned.md`, and `.ai/rules/accessibility.md` because `surfaces.accessibility` is true. `.ai/rules/infrastructure.md` is in the infrastructure review. No database rule applies (`surfaces.database` is false).

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-ARCH-001 | minor | `Gate.checks_for` and `Gate#evaluate` | `checks_for` adds `panel recorded` for every phase in `panel_phases`. `evaluate` runs `panel_check` only when the handoff's `panel` is a Hash and status is `complete`. The snapshot page lists checks from `checks_for` (`lib/soft_foundry/snapshot.rb`). A blocked split never runs the check either, which matches the gate's rule that a blocked phase is reported and not failed. | A completed `specify` that was not a panel, opened in `soft-foundry ui`, is described as having been through `panel recorded`. `soft-foundry gate specify` does not run that check. The page and the gate disagree. | `.ai/rules/general.md` (important invariants should have one enforceable place) |
| REV-ARCH-002 | minor | implementation deviation 1 | Implementation wrote `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, and `README.md`, which its write set denies. Review accepts the exception: REQ-PN-001, REQ-PN-005, and REQ-PN-010 require them, and no skill may write those paths. The maintainer still accepts the control-plane edit at merge. | None in the product. Recording it is what stops a later reader treating an out-of-policy write as an unnoticed bypass. | `.ai/rules/general.md` (changes outside the approved scope are documented deviations) |

`Panel#fingerprint_phase_folder` and `Panel#fingerprint_outputs` both skip `handoff.yml`. The argument-stage output fingerprint also uses `Dir.glob` without `File::FNM_DOTMATCH`, while the independent fingerprint uses it. Shell narrowing only refuses phase-folder paths and other staging directories. Those three choices are why REV-SEC-007, REV-SEC-008, REV-SEC-009, and REV-SEC-010 are reachable. They are security findings; the structure is this one.

## What holds

`Panel` is one object for membership, prompts, staging, and agreement. `CLI` owns process lifetime, the handoff's `panel:` and `executed_by` blocks, and split parking. `Guard` narrows and does not widen. Codex stays a fresh session per stage because it cannot be handed an id. Agreement is position in the file the runner observed, not a heading the member chose. The workflow lint refuses `implement` and unknown phase ids in `panel_phases`. Decisions in `05-implementation/decisions.md` match the code. Ruby style is ordinary: no rescued `Exception`, no new global, keyword arguments on `Panel.new`.

The fingerprint now runs before the independent round and fails the argument immediately when a watched draft or phase output changes. That closes the ordering behind the second review's REV-SEC-005 and REV-SEC-006 for the files it includes.

## Conformance

Conforms, with the two minors above. The accepted control-plane writes are the exception in REV-ARCH-002. The fingerprint gaps are security findings, not a second architecture defect.
