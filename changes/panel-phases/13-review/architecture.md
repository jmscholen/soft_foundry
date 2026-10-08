# Architecture Review

## Scope reviewed

`Panel` against `PhaseRunner` and `Guard`, the `panel_phases` workflow key, `Gate.checks_for` versus `Gate#evaluate`, and the decisions in `05-implementation/decisions.md`. Rules: `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-ARCH-001 | minor | `Gate.checks_for` and `Gate#evaluate` | `checks_for` adds `panel recorded` for every phase in `panel_phases`. `evaluate` runs `panel_check` only when the handoff's `panel` is a Hash, and only when status is `complete`. The snapshot page lists checks from `checks_for` (`lib/soft_foundry/snapshot.rb`). A blocked split never runs the check either, which matches the gate's existing rule that a blocked phase is reported and not failed; the list still claims the check runs. | A completed `specify` that was not a panel, opened in `soft-foundry ui`, is described as having been through `panel recorded`. `soft-foundry gate specify` does not run that check. The page and the gate disagree. | `.ai/rules/general.md` (one place for an invariant); same drift called out for other phase-specific checks in changes/ui-snapshot |
| REV-ARCH-002 | minor | implementation deviation 1 | Implementation wrote `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, and `README.md`, which its write set denies. Review accepts the exception: REQ-PN-001, REQ-PN-005, and REQ-PN-010 require them, and no skill may write those paths. The maintainer still accepts the control-plane edit at merge. | None in the product. The failure avoided by recording it is a later reader treating an out-of-policy write as an unnoticed bypass. | `.ai/rules/general.md` (changes outside the approved scope are documented deviations) |

## What holds

`Panel` is a single object for members, prompts, agreement, and the handoff block. `CLI` owns process spawning and the change status. `Guard#narrow_for_panel` only restricts. That matches the layering already used by `PhaseRunner`. Decisions with lasting effect (agreement read from appended bytes, sequential argument rounds, first member writes consensus, split parks the change, Codex starts fresh) are in `05-implementation/decisions.md`. Ruby in the new file follows `.ai/rules/ruby.md`: small public API, keyword arguments, no rescue of `Exception`, no metaprogramming. No new dependency.

The `checks_for` / `evaluate` split is the same shape as the existing phase-specific checks. REV-ARCH-001 is the panel-shaped instance, not a new kind of structure.

## Conformance

Conforms, with the accepted control-plane exception (REV-ARCH-002) and the check-list drift (REV-ARCH-001).
