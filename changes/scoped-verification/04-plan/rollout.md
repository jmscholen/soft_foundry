# Rollout

## Deployment ordering
Soft Foundry is a locally built and installed gem; there is no deployed service. Ordering is by commit within the change branch, which is stacked as change A of three (B and C follow and must not start from this branch before it merges):
1. Git wrapper and declaration validation, with tests.
2. Scope module, staleness delegation, consumers.
3. Full-suite check and sizing, policy, CLI.
4. Advisories, templates, skills, docs, harness evals.
Each commit leaves the existing suite and `soft-foundry check` green. After merge, release is a local gem build installed under the asdf Ruby the global wrapper uses; no gem is pushed to RubyGems.

## Migrations and backfills
N/A. All fields are optional. Existing records and repositories behave as today until a repository adds `shared_core`/`access_control` to `.ai/repository.yml` or a record adds `scope:`. Open records of this repository are not edited. `soft-foundry check` must pass on existing repositories without the new keys.

## Feature flags and gradual exposure
No flag. The declaration itself is the opt-in: no `scope`, no change. First real use is the `my_ai` engagement, where a maintainer declares `shared_core` (ApplicationController, User, auth, paywall) and `access_control`, then scopes one low-risk record first and compares `soft-foundry change size` output with their own judgment before scoping the rest.

## Success signals to watch
- `soft-foundry check`, the full suite, and harness evals pass in CI on the change branch.
- On a fixture or the engagement repository: an isolated change leaves sibling records current; a shared-core change stales all; `change size` names triggering paths.
- Advisories appear for scope overrun and core-without-full-run.
- Fewer repeated full-suite runs per tree (one recorded run cited by several records).
- No report of stale evidence passing; any such report is treated as a blocking regression and rolled back.
