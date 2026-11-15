# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| One module, `ProcessRules`, answers every rule question | Logic spread through Gate, PhaseReopen, PhaseSeal, Sizing | One definition of a round, a tier, a decision and a documentation path | Each caller is a few lines; tests target the module |
| `rules: 2` written by `ChangeRecord#declare_rules!` in code | A `rules:` line in `.ai/templates/change/metadata.yml` | Works before the control-plane text is changed and cannot be dropped by editing a template | The template gains a matching comment under the override |
| Round count = max(`Record <slug> remediate` commits from the branch tip, reopen entries that reset a complete remediation) | Either source alone | THREAT-002: both git history and metadata must be rewritten to lower the count | readme-workflow-visuals' history counts 8 |
| Cap enforced at reopen, at the remediate seal, and at the review and judge gates | Reopen only | A round reached without a reopen, or a hand-edited status, is still caught (MIT-002, MIT-003) | Three places call the same `another_round_allowed?` |
| Parking writes only `status: awaiting_human` | Also append a history entry | A refusal changes nothing else (spec failure behaviour) | The advisory and the refusal text say what to record |
| `blocked_by` in 14-judgment/evidence.yml | A field in final.md | evidence.yml already holds `criteria_not_covered`; structured and parseable | final.md stays prose |
| `outside_change` findings must name `paths`, checked against the change's diff from the plan commit | Trust the flag | THREAT-006: an in-change finding cannot be relabelled | A reviewer must say what code a follow-up concerns |
| Documentation = DOCS group, top-level `*.md`, `changes/<slug>/**`; never `.ai/**` | Include `.ai/` | The control plane is instructions, not documentation (THREAT-004) | Skill-text-only remediations still rerun the tail |
| Release carries person checks as items with `from: person_check` | Require `--item` for each | REQ-007: the person check is never lost | `--item` may be omitted when person checks exist |
