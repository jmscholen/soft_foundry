# Converging changes: promises, rounds and follow-ups

Introduced by `changes/process-speed` (REQ-001 to REQ-017). Applies to records with `rules: 2` or above in `metadata.yml`, which `soft-foundry change new` writes. Older records keep the rules they started under.

## Approve what the change promises
1. Write each acceptance criterion with `tier: must` or `tier: should` in `02-specification/acceptance-criteria.yml`. Must is for what would be a real failure of the change's purpose, security or data.
2. Keep the must count within the cap for the change's risk (`.ai/workflow.yml` `must_criteria_cap`; low 3, medium 8, high 15). The `criteria tiered` check says when it is over.
3. Put checks only a person can make under `person_checks`, not in the criteria.
4. A person records the approval in `metadata.yml`:

   ```yaml
   human_decisions:
   - boundary: must criteria approval
     criteria: [AC-001, AC-002]
     decided_by: <name>
     decided_at: <date>
     decision: approved
   ```

   The `must criteria approved` check fails, and `phase seal specify` refuses, until the list matches the must criteria exactly.

## When remediation reaches the cap
After two sealed remediation rounds (`remediation.max_rounds`), `phase reopen remediate`, an automatic reopen by `phase run`, and `phase seal remediate` refuse and set `status: awaiting_human`. The refusal names what to record:

```yaml
- boundary: remediation cap
  rounds: 2
  decision: accept_residual   # or narrow, or reject
  decided_by: <name>
  decided_at: <date>
```

Then set `status: in_progress`. `accept_residual` and `narrow` let one more round through; `reject` never does. The `remediation within cap` check at review and judgment fails while a round beyond the limit has no decision. `phase run` starts no session while the change is `awaiting_human`.

## A BLOCKED judgment names its basis
List in `14-judgment/evidence.yml` `blocked_by:` the must criteria or blocking review findings it rests on. The `blocked basis` check refuses a should criterion, a finding that is not `blocking`, one without a `failure`, or one marked `outside_change`.

## Findings about code the change did not modify
Mark the finding `outside_change: true` with `paths: [...]` and `follow_up: <where it goes>`. It appears as a `follow-up` advisory in `change status` and never blocks. The `outside-change findings` check refuses the mark when one of the paths changed in this change.

## A lighter loop
- At low risk, the phases low risk may waive are stepped over unless listed under `run_phases:` in `metadata.yml`, except the specification, so a person still approves the must list; `waivers permitted` lists them.
- A diff that changes only documentation (the `DOCS` group, top-level Markdown, the change's own record; never `.ai/`) is sized small by `soft-foundry change size`.
- `soft-foundry phase reopen remediate --docs-only --reason TEXT` keeps verification, evaluation and attack evidence; `phase seal remediate` then refuses if any path outside documentation changed since the reopen.

## Limits
The gate reads that a decision is recorded, not who wrote it. Recording a decision a person did not make is fabricating evidence; the seal names hand-edited metadata keys, and review reads the decisions.
