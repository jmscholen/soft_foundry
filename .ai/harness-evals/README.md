# Harness Evals

These evaluate Soft Foundry and its autonomous skills, not application feature behavior. Feature acceptance belongs to the `evaluation` skill. Harness evals measure whether the gate refuses the records it should refuse and whether a fresh-context phase finds a planted defect. Every execution skill is denied this directory (read and write), so the agents being measured cannot see or tailor the cases; `soft-foundry eval` prints ids, descriptions, and outcomes, never case content.

## Running

```bash
soft-foundry eval                                   # every gate case; one status line each, then a summary; exit 0 only if all pass
soft-foundry eval --case judgment-waived --json     # some cases, as data
soft-foundry eval --live --shell claude             # also the live cases, each in a fresh session through `phase run`
soft-foundry ci                                     # runs the gate cases after the control-plane lint
```

A case runs in a scratch git repository under the system temp directory carrying a copy of this repository's `.ai/` (minus this directory), an application file in the `APP` path group and a test file in `TESTS`, a scaffolded change record, and whatever the case plants. The scratch repository is removed when the case ends, exceptions included.

## Writing a case

One file per case, `cases/<id>.yml`, `id` equal to the file name. `soft-foundry check` lints every case.

```yaml
id: evidence-stale-after-code-change
kind: gate                    # gate | live
description: Application code edited after verification was recorded makes the evidence stale.
record:                       # the planted change record
  risk: low                   # metadata.yml risk (default low)
  track: gated                # optional; a track from .ai/workflow.yml
  status: in_progress         # optional; intake | in_progress | exploring | awaiting_human
  complete: [intake, discover, specify, threat_model, plan, implement, verify]   # phases recorded complete at the bound commit, templates filled
  skipped: [attack]           # phases named in skipped_phases (rationale supplied)
  handoff:                    # keys merged into a phase's handoff after completion
    review:
      findings: [{id: REV-001, severity: major, summary: planted}]
  files:                      # files written into the record before it is committed
    06-verification/tests.yml: "..."
  commit: true                # false leaves the record uncommitted
  later_files:                # files written into the record after the commit (uncommitted edits)
    02-specification/requirements.yml: "..."
repository:                   # files written into the scratch repository after the record is complete
  files:
    "${APP_FILE}": "puts 2\n"
  commit: false               # true commits them
expect:
  phase: verify               # the phase gated
  check: evidence current     # optional; a check name from Gate::CHECKS; without it the whole phase's outcome is compared
  outcome: fail               # pass | fail
```

Tokens in file contents: `${COMMIT}` (the commit the phases were bound to), `${APP_FILE}` (a code file in the `APP` group, also usable as a path key), `${CANARY_AWS}` and `${CANARY_OPENAI}` (secret-shaped canaries) and `${INVISIBLE_ZWSP}` (a zero-width space), which the runner builds so that no case file carries one. Paths are relative, inside the tree, and never traverse upward; a case may write at most 200 files.

A live case names the `phase` to run and plants application files before the record exists:

```yaml
id: review-finds-planted-defect
kind: live
phase: review
description: ...
application:
  files:
    "${APP_FILE}": "..."
record:
  complete: [intake, discover, specify, threat_model, plan, implement, verify, evaluate, attack]
  files:
    00-intake/request.md: "..."
expect:
  finding: "cap|exceed"        # a regular expression over the phase's handoff findings (summary, failure, id) and its Markdown files
```

`eval --live --shell <shell>` runs `phase run <phase> --shell <shell>` in the scratch repository (arguments after `--` go to the shell) and records the shell and the `resolved_model` the session wrote. A session that exits non-zero is an error; a session that completes the phase without a matching finding is a fail (the miss is the measurement). Live sessions run as you, in the scratch repository, with the host's own permission mode: there is no sandbox beyond the directory.
