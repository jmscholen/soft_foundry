# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| `change new` option parsing and usage text | `lib/soft_foundry/cli.rb:292` | Adds `--type` and `--risk`, validates against allowed lists, refuses unknown values with the list | discovered |
| `ChangeRecord.create` and scaffold | `lib/soft_foundry/change_record.rb:19` | Must write `type` and `risk` into `metadata.yml` at creation; omitted values keep the template's placeholder values | discovered |
| Metadata template | `.ai/templates/change/metadata.yml` | Holds the vocabularies only as comments; possible single source of the allowed values | discovered |
| Task and risk vocabularies | `.ai/workflow.yml` (`waivable_by_risk`, `tracks.forced_by_risk`), `.ai/policies/` task and risk policy | The risk set must agree with these; a high risk forces the gated track | discovered |
| Phase runner finish path | `lib/soft_foundry/phase_runner.rb:197` and call sites `cli.rb:1120`, `cli.rb:1233` | Where the runner would set `complete` with blocking items to `blocked` and report it, in single and parallel runs | discovered |
| Gate blocking checks | `lib/soft_foundry/gate.rb:104-115` | Defines the failure the runner now pre-empts; must keep failing hand-edited records | discovered |
| Skill guidance for invisible characters | `.ai/skills/adversarial-testing/SKILL.md`, `.ai/skills/verification/SKILL.md`, `.ai/skills/review/SKILL.md`; README content-scan section (line 140) | Text telling agents to write payloads as visible escapes or build them in scripts | inferred (which skills carry it is a plan decision) |
| Content scan | `lib/soft_foundry/content_scan.rb` | Not changed (assumption); its behaviour is what the guidance must work with | discovered |
| Status command and summary | `lib/soft_foundry/cli.rb:594` (`status`), `lib/soft_foundry/snapshot.rb` (`change`, `board_row`, `recorded_cell`, `state`) | New short latest-state view built from existing records; subcommand name and layout open | discovered |
| Finding counts source | per-phase `handoff.yml` `findings:`, review and attack evidence files, `ChangeRecord` readers | The summary reports newest finding counts; format of findings differs by phase | inferred |
| Accessibility rule | `.ai/rules/accessibility.md` | The new summary is CLI output; must read without colour, in order, with text status words | discovered |
| Access-control profile key | `lib/soft_foundry/control_plane.rb:290`, `sizing.rb:102`, `scope.rb:177`, `check.rb:171` | Existing `access_control` globs name the paths the parity rule applies to | discovered |
| Parity rule file | `.ai/rules/` (new file, e.g. access-control parity) and `.ai/skills/verification/` guidance | Declares the rule; verification must record the protection state it ran with | inferred |
| Verification evidence shape and gate | `.ai/skills/verification/template/tests.yml`, `lib/soft_foundry/gate.rb` (`CHECKS`, `checks_for`) | A field recording protection state and a structure-only check that it is stated when a changed path matches `access_control` | inferred |
| Harness evals | `.ai/harness-evals/cases/` (deny_read for discovery; not inspected) | A gate case for the new check and the blocked-marking is likely wanted; content not read | inferred |
| Tests | `test/**` (minitest; `with_fixture_repo` helper per `repository.yml`) | New tests for each of the five fixes | discovered |
| README and schemas | `README.md`, `.ai/schemas.md` | Document new flags, the summary, the new handoff behaviour and the new profile and record fields | discovered |
| Version | `lib/soft_foundry/version.rb`, `soft_foundry.gemspec` | Released behaviour change; bump policy owed to plan | inferred |
