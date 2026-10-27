# Consolidated Review

## Functional

Conforms on creation, single-run and auto-reopen blocked marking, summary prefixes, invisible-character guidance, and the `protection stated` check. One major finding: `phase run --parallel` marks the phase blocked and prints failure, then exits 0 (REV-001). Minors: equals-form and repeated `--type` are ignored (REV-002), a non-Array `blocking` or `findings` value is shown as none and is not marked (REV-003), and `check` does not compare `tracks.forced_by_risk` keys to the risk vocabulary (REV-006).

## Architecture

Conforms, with REV-001. `ChangeSummary` stays off the gate. The vocabulary has one constant. Blocked marking writes only the finished phase's handoff under the record lock. The exit-2 decision was applied on the single-run return only.

## Security

Conforms with advisories. No new network call, credential, or privilege. Control and format characters in the new output are escaped. Alias bombs in a handoff are refused. REV-004: a format character in an `access_control` glob skips `protection stated` (the control-plane content scan still flags the file when `check` runs). REV-005: `change summary` follows a symlinked handoff or metadata file. REV-007: `test/display_test.rb` embeds raw U+202E, U+200B, and U+2066. False `in_force` claims remain structure-only, as specified. This repository declares no `access_control`; the verification record's `not_applicable` values match that.

## Accessibility

Conforms with advisories (`.ai/rules/accessibility.md` command-line and document rules). REV-008: the `warn:` line after a failed mark does not say what to do next. No HTML or native UI.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms are NOT_APPLICABLE in `.ai/repository.yml`, and the diff adds no collection, recipient, retention, or promise. Policy text changes owed: None.

## Infrastructure

N/A. No infrastructure-as-code in the repository, and none in the diff.

## Operations

Conforms with REV-001 and REV-009. Searchable lines exist for a blocked run, the summary, and `protection stated`. The parallel process status does not carry the blocked result. The suite is not isolated from an inherited `SOFT_FOUNDRY_PHASE` (VER-001); it passes with the variable unset. `12-observability/` is still the template; the phase is optional and this change declares no observability surface.

## Blocking findings

None. REV-001 is major. Judgment decides whether the parallel exit status goes back through remediation.

## Residual concerns

- Attack left four low violations unrepaired. They are REV-002, REV-003, REV-004, and REV-005. Remediation (`09-remediation/`) was not run; its files are still the template.
- IMPL-001 and the README half of IMPL-002 were closed by `cf932d1` (rule, three skill paragraphs, `tests.yml` template comments, README, `.ai/schemas.md`). The gemspec already reads `SoftFoundry::VERSION`.
- Harness-eval cases were not added. The plan left them to a phase allowed to read `.ai/harness-evals/`. This review did not read that tree. Unit and integration tests cover the new behavior, except the parallel exit status (REV-001).
- `protection stated` does not check that an `in_force` claim is true (IMPL-004, THREAT-006). Specified limit.
- `phase run --panel` does not call `mark_blocked`. REQ-005 does not name the panel path.
- Phases 10, 11, and 12 are optional and still pending.
- Implement and the later evidence phases recorded provider anthropic. This review used xai.
