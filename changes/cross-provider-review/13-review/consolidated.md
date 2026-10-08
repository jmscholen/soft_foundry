# Consolidated Review

Reviewed at `2bcd186a2e6b97178c196bef26a05d7ec29100ed`. Library, tests, README, and `.ai/` match the verified commit `53e4108fc38bb3077a3057b161328067ca06dc7e`.

Rules applied: baseline `general` and `architecture`; discovery's `ruby` and `testing`; `security`, `errors`, `git`, `dependencies`, `observability`, and `learned`. No database and no Rails. No infrastructure-as-code tool. Accessibility and policy conformance are in their own files. `learned.md` is satisfied: the failing tests were committed at `eb3ace3` and `e62bc6e` before the fixes, and the evidence after REM-001 was regenerated rather than annotated.

## Functional

Conforms with a major finding. REQ-XP-001, REQ-XP-004, REQ-XP-005, REQ-XP-006, and REQ-XP-007 hold. REQ-XP-002 holds for the accepted names and for a blank provider falling through to the shell. REQ-XP-003 holds when every completed named phase resolves, and fails when one resolves and another does not (REV-FUN-001): the probe started claude, the implementer's provider, while a known provider of anthropic was already on the record. The RED-test setup fix and the grok usage line are approved.

## Architecture

Conforms. `PhaseProvider` exists so the advisory does not load the runner. The preference is on the two skills, not on the shared profile. Control-plane and README writes outside the implementation write set are accepted: the requirements demand them, and the diff is only those edits.

## Security

Conforms. The launched executable is an allowlisted shell. The advisory-silencing residual (a canonical provider that is not the shell) and the structural `failure: n/a` residual are the ones attack recorded. REV-FUN-001 is a wrong default, not an injection.

## Accessibility

Conforms. Declared surface. The new lines use the prefix `shell:` or the word `warn`, are ASCII, do not prompt, and do not depend on color or width. No finding. The skipped specification phase will still draw the go-live advisory that no accessibility requirement was recorded. That advisory is about the skip, not about this review.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms are NOT_APPLICABLE in `.ai/repository.yml`. Nothing new is collected, shared, or retained. No policy text change is owed.

## Infrastructure

N/A. No infrastructure-as-code tool is recorded, and the diff touches none.

## Operations

Conforms for a library with no deployed service. The `shell:` line, the warning, and the same-provider advisory are the operator surface. The observability phase has not run and is optional. REV-FUN-001's warning names the unresolved phase and not the known provider the chosen shell collides with; the post-run advisory still fires if the review records that provider.

## Blocking findings

None.

## Residual concerns

- `failure: n/a` passes `findings explained`. The intake says the check is structural. ATTACK-001 recorded it.
- A review that writes a different canonical provider silences the same-provider advisory. ATTACK-002 and the implementation decision recorded it. An unrecognized provider string also yields nil and skips the advisory; that path is part of REV-FUN-001's second input, not a separate residual.
- On this machine the default for an anthropic implementation is codex, whose login has expired (EVAL-OBS-001). The intake non-goal stands: `--shell grok` is how this review was run.
- User-documentation, FAQ index, and observability phases are still pending. README covers REQ-XP-007. Those phases are optional; this review did not fill them.

## Unresolved findings

- REV-FUN-001 (major). `phase run review` or `phase run judge`, with no `--shell`, starts the first installed shell when any of `prefer_different_provider_from` has no resolvable provider, including when another of those phases has a known provider that the first shell matches.
