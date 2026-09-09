# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Gem packaging | `soft_foundry.gemspec` | Must ship the installable control plane and scaffolding; must stop shipping this repository's own `repository.yml` state and `harness-evals/` unless intended | discovered |
| CLI dispatch | `lib/soft_foundry/cli.rb` | `init` and `onboard` are aliases; `init` needs its own command path, options for conflict strategy, and a created/updated/skipped/conflict report | discovered |
| Onboarding | `lib/soft_foundry/onboarding.rb` | Owns `.gitignore` and runtime discovery; `init` composes it | discovered |
| Agent file adapters | `lib/soft_foundry/agent_files.rb` | `AGENTS.md` needs a marker-based safe update instead of write-when-missing; `CLAUDE.md` behavior is already correct | discovered |
| New installer | `lib/soft_foundry/installer.rb` (proposed) | Copies canonical `.ai/`, `changes/README.md`, `docs/user/README.md` into a target root with per-file status | inferred |
| Packaged canonical sources | `.ai/**`, `changes/README.md`, `docs/user/README.md` | Become install inputs; `.ai/repository.yml` must be installed as the unassessed template | discovered |
| Control-plane lint | `lib/soft_foundry/check.rb` | Should pass on a freshly initialized target, which is the natural post-install verification | inferred |
| Doctor | `lib/soft_foundry/cli.rb` `doctor` | Should report an incomplete install | inferred |
| Tests | `test/` | New installer tests per the intake matrix; `test_helper.rb` fixture already builds a target repository | discovered |
| Documentation | `README.md`, `docs/user/` | Usage for `init`, conflict strategy, and idempotency guarantees | discovered |
