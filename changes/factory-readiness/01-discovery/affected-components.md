# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Gate | `lib/soft_foundry/gate.rb` | `placeholder_check` reads without an encoding; `specification_lock_check` runs only when vetted; `staleness_check` ignores `02-specification/`; a new first-phase check for waivers by risk | discovered |
| Advisory | `lib/soft_foundry/advisory.rb` | `fresh_context_notices` names only review and judgment; must cover every commit-bound phase | discovered |
| Change record | `lib/soft_foundry/change_record.rb` | `reached_lifecycle_end?` and `skippable?` accept any waived phase; `change close` relies on them | discovered |
| CLI | `lib/soft_foundry/cli.rb` | new `eval` command; `ci` runs the deterministic evals; `change close` refuses without a judgment; help text | discovered |
| Control-plane lint | `lib/soft_foundry/check.rb` | lint the eval cases and the waiver rule | discovered |
| Harness evals (new) | `lib/soft_foundry/harness_eval.rb`, `.ai/harness-evals/cases/**` | the eval runner and its cases | inferred (new) |
| Phase runner | `lib/soft_foundry/phase_runner.rb` | live evals launch `phase run review` in a scratch repository; the prompt is reused unchanged | discovered |
| Policy | `.ai/policies/enforcement.yml` | `guard.mode` becomes `block` | discovered |
| Workflow | `.ai/workflow.yml` | declares which phases a risk may waive | inferred (new key) |
| Skills | `.ai/skills/verification`, `evaluation`, `adversarial-testing` (SKILL.md) | say that the phase prefers a fresh session through `phase run` | discovered |
| Profile | `.ai/repository.yml` | stale findings and the missing `observability.standard_dashboard` entry; written by this discovery | discovered |
| Documentation | `README.md`, `.ai/schemas.md`, `.ai/README.md`, `AGENTS.md` | describe eval, block mode, the lock, waivers, and the advisory | discovered |
| Tests | `test/` (new `harness_eval_test.rb`, `application_repo_test.rb`, `factory_readiness_test.rb`) | RED then GREEN for each requirement | inferred |
| Hook settings | `.claude/settings.json`, `.codex/hooks.json` | unchanged; the mode is read from policy at hook time | discovered |
| Gemspec | `soft_foundry.gemspec` | `.ai/**/*` already packages the eval cases; `lib/**/*` the runner | discovered |
