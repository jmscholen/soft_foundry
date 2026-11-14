# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Phase reopen | lib/soft_foundry/phase_reopen.rb | Enforcement point for the remediation cap (refuse a third round, park at awaiting_human) and for a narrower reset after a documentation-only remediation | discovered |
| Phase seal | lib/soft_foundry/phase_seal.rb | A first remediation can be sealed without a reopen; `advance!` decides the next phase and could step over phases a docs-only remediation leaves current | discovered |
| Gate | lib/soft_foundry/gate.rb | New checks: criterion tiers and must cap, must-list approval before specify seals, person-only criteria refused, BLOCKED tied to a must miss or a blocking finding, round cap; `CHECKS` entries | discovered |
| Control plane | lib/soft_foundry/control_plane.rb | Reads new workflow and policy keys (round cap, must cap by risk, default waivers); `downstream` used by reopen | discovered |
| Change record | lib/soft_foundry/change_record.rb | `skippable?` for default low-risk waivers; helpers for counting remediation rounds and reading human_decisions by boundary | discovered |
| Sizing | lib/soft_foundry/sizing.rb, .ai/policies/check-sizing.yml | A documentation-only diff gets the smaller sizes | discovered |
| Advisory, summary, snapshot | lib/soft_foundry/advisory.rb, change_summary.rb, snapshot.rb | Report a capped or parked change, should-tier misses and out-of-change follow-ups as advisories | inferred |
| CLI | lib/soft_foundry/cli.rb, exe/soft-foundry | `change new` defaults for low risk; reopen and seal messages; help text | discovered |
| Check (lint) | lib/soft_foundry/check.rb | Lint new workflow and policy keys | discovered |
| Workflow | .ai/workflow.yml | Round cap, must caps by risk, default-waiver flag, docs-only rerun rule | discovered |
| Policies | .ai/policies/human-boundaries.yml, check-sizing.yml | New boundaries (remediation cap reached; must-list approval); docs-only sizing rule | discovered |
| Skills | .ai/skills/{specification,product-documentation,evaluation,adversarial-testing,review,final-judgment,remediation}/ | Tier and bounded-claim guidance; evaluate and attack aim at the must list; judgment and remediation thresholds; out-of-change findings as follow-ups | discovered |
| Templates | .ai/skills/specification/template/acceptance-criteria.yml, .ai/templates/change/metadata.yml | `tier:` field; release-item hint for person-only checks | discovered |
| Schemas doc | .ai/schemas.md | Document tier, new boundaries, round counting | discovered |
| Harness evals | .ai/harness-evals/cases/ | One gate case per new check (written by implementation under the override) | discovered |
| Tests | test/gate_checks_test.rb, cli_phase_reopen_test.rb, lifecycle_fixture.rb and new files | Coverage for each new rule | discovered |
| User docs | README.md, docs/user/ | Document the cap, tiers, approval and lighter loop | discovered |
