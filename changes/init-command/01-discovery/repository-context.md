# Repository Context

## Discovered
- **Language and runtime.** Pure Ruby gem, no application framework. Local toolchain is Ruby 3.3.1 via asdf; no `.ruby-version` or `.tool-versions` is committed. The gemspec declares `required_ruby_version >= 3.1`, but `lib/` uses `Data.define` in five files, which requires Ruby 3.2 or later.
- **Architecture.** Two layers. `.ai/` is a declarative control plane (workflow, skills, rules, policies, profiles, path groups, templates) read by `SoftFoundry::ControlPlane`. `lib/soft_foundry/` is a CLI: `CLI` dispatches to `Onboarding` (gitignore, agent files, provider discovery), `AgentFiles` (AGENTS.md and CLAUDE.md), `Providers`/`Provider` (HTTP model inventory), `Shell` (launch coding shells), `ChangeRecord`, `Gate`, `Check`, `Hooks`, and `Git`.
- **Existing init behavior.** `init` and `onboard` are aliases; both run `Onboarding#run`, which appends `.soft-foundry/` to `.gitignore`, writes a minimal `AGENTS.md` only when absent, appends a marker block to `CLAUDE.md`, and writes `.soft-foundry/runtime.yml`. Nothing installs `.ai/`.
- **Packaging.** `spec.files` globs `lib/**/*`, `exe/*`, `README.md`, `AGENTS.md`, `.ai/**/*`. A `gem build` confirms `.ai/` ships with 135 skill files, and also ships `.ai/repository.yml` (this repository's own assessment, once populated), `.ai/harness-evals/`, and this repository's `README.md`. It does not ship `changes/README.md`, `docs/user/README.md`, `Gemfile`, or tests.
- **Marker convention.** `AgentFiles::CLAUDE_MARKER` (`<!-- soft-foundry:canonical-agent-reference -->`) is the only idempotency mechanism in the codebase. `AGENTS.md` has no marker; it is written only when missing.
- **Tests.** Minitest under `test/`, run by `rake test` and by `.github/workflows/ci.yml`. Six test files, 27 tests. `test/test_helper.rb` provides `with_fixture_repo`, which builds a throwaway git repository carrying a copy of `.ai/`, and `cli` for driving `SoftFoundry::CLI` with captured output.
- **Deterministic checks.** `soft-foundry check` lints `.ai/`; `soft-foundry ci` gates every change record; both run in CI and in the installed pre-commit hook.
- **Infrastructure.** None. Delivery target is RubyGems; the only automation is GitHub Actions. No IaC, database, or deployed service.
- **Security boundaries.** Provider API keys are read from environment variables and used only for outbound HTTPS model listing; never written to the repository. `.soft-foundry/` is machine-local. `.ai/policies/**` and `.ai/harness-evals/**` are protected from every skill's write set; `.ai/repository.yml` is the sole control-plane file discovery may write.

## Inferred
- `init` is intended to become "install the control plane" while `onboard` remains "discover runtime and repair adapters", with `init` calling onboarding at the end. This follows from the README's usage text and the intake record; the code does not yet distinguish them.
- Target repositories will usually have their own `AGENTS.md`, so the safe-update requirement implies a marker block for `AGENTS.md` mirroring the `CLAUDE.md` mechanism.
- Conflict detection for `.ai/` needs a record of what Soft Foundry installed, because there is currently no way to tell a canonical file from a user-edited one.

## Defined by repository policy
- `.ai/paths.yml` groups for this repository should be `APP: [lib/**, exe/**]`, `TESTS: [test/**]`; the defaults also list `app/`, `config/`, `db/`, and `spec/`, which do not exist here. Recorded in `.ai/repository.yml`.
- Discovery must not modify product code (`SKILL.md`); this phase changed only `changes/init-command/01-discovery/` and `.ai/repository.yml`.
- Work lands through a pull request from `change/init-command` (intake constraints).

## Unknown
See `unknowns.md`.

## Affected components
See `affected-components.md`.

## Dependencies
See `dependencies.md`.
