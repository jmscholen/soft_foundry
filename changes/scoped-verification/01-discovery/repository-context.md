# Repository Context

Assessed at commit fb74c5fe01085f14c06bc29154b64f68d42da009 (branch change/scoped-verification, stacked on main after PR #50).

## Discovered
- Soft Foundry is a Ruby 3.3 gem (`exe/soft-foundry`, `lib/soft_foundry/*.rb`, about 7,700 lines) with Minitest tests under `test/` run by `bundle exec rake test`, and `bundle exec rake ci` (`soft-foundry ci`: lint `.ai/` and gate every change record). GitHub Actions (`.github/workflows/ci.yml`) runs both on push to main and on pull requests, with `fetch-depth: 0`.
- The rule deciding when commit-bound evidence is stale is `Gate#staleness_check` (`lib/soft_foundry/gate.rb:375`). It takes the handoff's `commit_sha`, asks `Git#changed_since(sha)` (committed diff to HEAD plus every dirty, untracked and ignored path), keeps paths matching `ControlPlane#code_globs` (the `APP`, `TESTS` and `INFRA` path groups, with `repository.yml` `paths:` overriding `paths.yml` per group), and fails with `STALE` if any remain. There is no notion of which change a file belongs to, so one code change stales every record on the branch. This is the field complaint.
- A stacked-branch refinement exists: when the record's branch (`metadata.git.branch`) exists and is not checked out, the diff is measured to that branch's tip with `Git#changed_between` (committed changes only) instead of the worktree.
- A second staleness cause, "specification re-recorded after this evidence", compares the specify handoff's lock commit with the phase's own handoff commit. It is independent of code scope and must stay unscoped.
- Which phases are commit-bound is `evidence: commit_bound` in each `skill.yml` (`Skill#commit_bound?`). Staleness consumers: `Gate::Result#stale?`, `PhaseRunner#refusal` (a complete phase may be rerun only when stale), and `Snapshot` (`stale` and `fail` states shown by `status` and the `ui`).
- Verification evidence today: `06-verification/{results.md,tests.yml,evidence/manifest.yml,handoff.yml}`. `tests.yml` has `commit_sha` and `checks:` (id, kind, command, result, evidence, criteria, optional `red_commit`/`test_path`). The gate's `red evidence` check validates the shape of a `red_commit` claim against git. Nothing records a tree hash, and nothing lets one verification cite another change's run.
- `Git` (`lib/soft_foundry/git.rb`) is a thin `git -C` wrapper with no tree-hash helper; `git rev-parse HEAD^{tree}` is available (git 2.39 here). Metadata (`changes/<slug>/metadata.yml`) has `surfaces`, `skipped_phases`, `risk`, `track`, `vetted`; no scope field. `.ai/repository.yml` has `paths:` overrides and no shared-core key. Both schemas are documented in `.ai/schemas.md`.
- Check sizing: no policy under `.ai/policies/` today decides how large verify, evaluate or attack must be. Skill text (`.ai/skills/verification/SKILL.md`) only says to run the repository-defined deterministic checks.
- Authentication and authorization: none. This is a local CLI. The security-relevant boundaries are the runtime guard (`guard.rb`, read/write/deny per skill `permissions.yml`), protected policy paths, and the anti-fudging rules; the guard currently blocks even shell reads of `.ai/policies` and harness evals from this skill.

## Inferred
- Because the gate is structural, "reuse" can only be a gate check that a cited run record names a tree hash equal to the evidence commit's tree (or the tree the citing record's commit_sha has) and a recorded outcome; it cannot prove the suite passed (see `soft-foundry-gate-scope`).
- Tree-hash equality is a strong identity: the same tree hash means byte-identical tracked content, so a run on a different commit with the same tree is valid for the new commit. Uncommitted or ignored files are outside it; the gate must decide how to treat a dirty worktree (the existing check includes dirty paths, so a dirty worktree cannot silently reuse).
- "Alters access control" cannot be computed from a diff by Soft Foundry without a repository-declared set of access-control paths; the natural home is the same declaration mechanism as shared core (an `.ai/repository.yml` key) and the diff-versus-glob computation lives in the gate or a CLI command.
- The default (no declared scope) must reduce exactly to today's `changed_since` over `code_globs`, so existing records, `harness-evals` cases and tests are untouched.

## Defined by repository policy
- Gate is structural and never judges content (`AGENTS.md`, memory). `check` validates control-plane structure and scans for instruction-override and secret shapes. Control-plane changes keep templates, `check`, harness evals, `.ai/README.md` and `.ai/schemas.md` in step. Review and judgment are never waived; a high-risk change waives nothing. Any implementation change invalidates downstream commit-bound evidence and returns to verify. `.ai/policies/**`, `.ai/skills/**`, `.ai/rules/**`, `workflow.yml` and `maturity.yml` are protected from the discovery skill; implementation of this change, not discovery, edits them.
- Surfaces declared: application, security and accessibility true (CLI output is perceived by a person); database, infrastructure, observability, policy false.

## Published policies
Privacy, security and terms are each recorded `NOT_APPLICABLE` under `policies:` in `.ai/repository.yml` (library gem and developer tool, no service or user data; maintainer decision 2026-09-15 for the security policy). No SECURITY.md or privacy/terms document exists, and this change does not alter what the tool collects, shares, retains or promises, so `surfaces.policy: false` stands.

## Unknown
See unknowns.md. Open design questions the specification must close: scope declaration syntax, where shared core and access-control paths live, the dirty-worktree rule, and how a cited full-suite run is stored and located.

## Affected components
See affected-components.md.

## Dependencies
See dependencies.md.
