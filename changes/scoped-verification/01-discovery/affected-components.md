# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Staleness check | lib/soft_foundry/gate.rb (`staleness_check`, `CHECK_DESCRIPTIONS`, `Result#stale?`) | The rule to scope: filter changed paths by the change's declared scope plus shared core instead of all of `code_globs`; add a check that a cited full-suite run matches the tree hash | discovered |
| Git wrapper | lib/soft_foundry/git.rb | Needs a tree-hash helper (`rev-parse <sha>^{tree}`); `changed_since`/`changed_between` keep their semantics | discovered |
| Path groups and profile | lib/soft_foundry/control_plane.rb (`code_globs`, `repository_profile`, `override_path_groups`) | Reads the repository-declared shared core and access-control globs from `.ai/repository.yml` | discovered |
| Change record | lib/soft_foundry/change_record.rb, `.ai/templates/change/metadata.yml` | Carries the declared `scope` path globs; absent means whole repository | discovered |
| Structure check | lib/soft_foundry/check.rb | Validate shared-core and scope globs, the new policy file, and templates in step | discovered |
| Phase runner | lib/soft_foundry/phase_runner.rb (`refusal`) | Consumes `stale?`; must follow the scoped result so a still-current phase is not rerun | discovered |
| Snapshot and UI | lib/soft_foundry/snapshot.rb, lib/soft_foundry/ui/ | Show `stale` per record; follow the gate's result, likely no logic change | inferred |
| CLI | lib/soft_foundry/cli.rb (`change new`, `gate`, `change status`, possibly a command that computes check size from the diff) | Declaring scope at creation, reporting size/scope in status, computing the verify size from the diff | inferred |
| Advisory | lib/soft_foundry/advisory.rb | May advise on a scoped change touching shared core without a full-suite run, or on a declared scope that the diff exceeds | inferred |
| Verification skill | .ai/skills/verification/{SKILL.md,template/tests.yml,template/results.md,template/evidence/manifest.yml} | Record tree hash, command, outcome of the full-suite run, or a reference to an existing run | discovered |
| Evaluation and attack skills | .ai/skills/evaluation/, .ai/skills/adversarial-testing/ | Same split: touched doors plus smoke, full sweep only when access control changes | discovered |
| Check-sizing policy | .ai/policies/ (new file, e.g. check-sizing.yml) | New policy: scoped change runs targeted checks plus one full run before merge; shared-core change runs full suite at verify, computed from the diff | discovered |
| Repository profile | .ai/repository.yml | New keys for shared core (and access-control paths); this repository declares none (no shared core, so defaults hold) | discovered |
| Workflow | .ai/workflow.yml | May name the sizing policy or scope rule under `rules:`; protected, edited by implementation | inferred |
| Docs for the control plane | .ai/README.md, .ai/schemas.md, README.md | Kept in step: new metadata field, repository key, tests.yml fields, check descriptions | discovered |
| Harness evals | .ai/harness-evals/cases/ (not read in discovery; denied) | Gate cases that plant a defective record must cover stale-in-scope, out-of-scope-current, shared-core, and tree-hash mismatch; implementation and verification own them | inferred |
| Tests | test/gate_test.rb, test/stacked_branch_test.rb, test/lifecycle_tracks_test.rb, test/factory_readiness_test.rb, new scoped-verification test | Existing staleness tests pin today's default and must stay green; new tests for scope, shared core, tree reuse | discovered |
