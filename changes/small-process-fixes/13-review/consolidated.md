# Consolidated Review

## Functional

Conforms on creation, single-run, auto-reopen, and parallel blocked marking, summary prefixes, invisible-character guidance, and the `protection stated` check. The previous major finding REV-001 is closed: `parallel_run` exits 2 when it marks a handoff blocked, and the new test passed when re-run at this commit. Minors: equals-form and repeated `--type` are ignored (REV-002), a non-Array `blocking` or `findings` value is shown as none and is not marked (REV-003), `check` does not compare `tracks.forced_by_risk` keys to the risk vocabulary (REV-006), a session that writes `blocked` itself is tallied as fail while the process exits 0 (REV-010), and the regression test for the parallel exit shares a commit with the fix (REV-011).

## Architecture

Conforms, with REV-010. `ChangeSummary` stays off the gate. The vocabulary has one constant. Blocked marking writes only the finished phase's handoff under the record lock. The exit-2 decision now applies on the single-run return and the parallel return. The parallel tally still uses a stricter word than the process status when the session wrote `blocked` itself.

## Security

Conforms with advisories. No new network call, credential, or privilege. Control and format characters in the new output are escaped. Alias bombs in a handoff are refused. REV-004: a format character in an `access_control` glob skips `protection stated` (the control-plane content scan still flags the file when `check` runs). REV-005: `change summary` follows a symlinked handoff or metadata file. REV-007: `test/display_test.rb` embeds raw U+202E, U+200B, U+2028, and U+2066. False `in_force` claims remain structure-only, as specified. This repository declares no `access_control`; the verification record's `not_applicable` values match that.

## Accessibility

Conforms with advisories (`.ai/rules/accessibility.md` command-line and document rules). REV-008: the `warn:` line after a failed mark does not say what to do next. No HTML or native UI.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms are NOT_APPLICABLE in `.ai/repository.yml`, and the diff adds no collection, recipient, retention, or promise. Policy text changes owed: None.

## Infrastructure

N/A. No infrastructure-as-code in the repository, and none in the diff. GitHub Actions CI is unchanged.

## Operations

Conforms with REV-009 and REV-010. Searchable lines exist for a runner-marked blocked run, the summary, and `protection stated`, and that run's process status is nonzero. A session-authored `blocked` status is searchable as `fail` and still exits 0. The suite is not isolated from an inherited `SOFT_FOUNDRY_PHASE` (VER-001); it passes with the variable unset (822 runs, 0 failures). `12-observability/` is still the template; the phase is optional and this change declares no observability surface.

## Blocking findings

None. REV-001 is closed. Every open finding is minor.

## Residual concerns

- Attack left five low violations. Four are REV-002, REV-003, REV-004, and REV-005. The fifth (ATTACK-012) is REV-010: the runner-marked path now exits 2, and a session that writes `blocked` itself still exits 0 while the tally says fail.
- The control-plane and README text from the implementation deviations is present: the parity rule, the three skill paragraphs, the `tests.yml` template comments, the README content-scan paragraph, and the `.ai/schemas.md` note. The gemspec already reads `SoftFoundry::VERSION`.
- Harness-eval cases were not added. The plan left them to a phase allowed to read `.ai/harness-evals/`. This review did not read that tree. Unit and integration tests cover the new behavior, including the parallel exit status. REV-011 is that the new assertion has no separate failing-test commit.
- `protection stated` does not check that an `in_force` claim is true (IMPL-004, THREAT-006). Specified limit.
- `phase run --panel` does not call `mark_blocked`. REQ-005 does not name the panel path. A panel that leaves `complete` with blocking items still fails the gate.
- Phases document, index, and observe are optional and still pending.
- Implement and remediate recorded provider anthropic. This review used xai.
