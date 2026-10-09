# Architecture Review

Reviewed at `661b454` (panel code identical to `4f3b2da`). Standards: `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`.

## Scope reviewed

`Panel` (`lib/soft_foundry/panel.rb`), the `panel_run` path in `lib/soft_foundry/cli.rb`, guard narrowing in `lib/soft_foundry/guard.rb`, the `panel recorded` check in `lib/soft_foundry/gate.rb`, and `panel_phases` in `.ai/workflow.yml`. The launcher is injected; tests stand in for the shells. That boundary is the right one.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-ARCH-001 | minor | `Gate.checks_for` versus `Gate#evaluate` | `checks_for` lists `panel recorded` for every panel phase. `evaluate` runs it only when a complete handoff has a `panel:` hash. | A panel phase marked `complete` with no `panel:` block does not fail `panel recorded`. REQ-PN-006 requires the check when the block is present, so the evaluate path matches the requirement. The check list overstates what a complete handoff without the block is put through. | REQ-PN-006 |
| REV-ARCH-002 | minor | `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/schemas.md`, `README.md` | Those writes are outside the implementation skill's write set. | No failure in the running system. REQ-PN-001, REQ-PN-005, and REQ-PN-010 require the edits, and no skill write set covers them. Accepted, same precedent as session-ledger and cross-provider-review. Recorded so judgment sees the deviation. | `.ai/rules/general.md` (changes outside the approved scope are documented deviations) |

The security findings REV-SEC-011..015 are failures of the check `Panel` owns (temp directory, `git ls-files` at process exit, no restore). They are not a second design layered beside it. Ownership of the check is explicit, which is what the architecture rule asks for. The check is the wrong shape; that is recorded under security, not repeated here.

`@members` is replaced when a member writes no draft. The mutation stays inside `Panel#run`, and `dropped` is what the handoff records. Codex still starts a fresh session per stage because `exec` cannot take an id. Both are recorded in `05-implementation/decisions.md` and match the code.

## Conformance

Conforms, with the accepted write-set deviation (REV-ARCH-002) and the check-list mismatch (REV-ARCH-001). Neither is blocking.
