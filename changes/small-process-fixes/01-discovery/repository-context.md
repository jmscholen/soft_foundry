# Repository Context

Commit described: 07ec16c7072c99829e9bf912332e9aaf9fcf295c (branch change/small-process-fixes). Scope: item 7 of the adopter field feedback, five small fixes (see `00-intake/request.md`).

## Discovered
- Soft Foundry is a plain Ruby gem (minitest, rake; no framework, no database, no deployed service). Code is `lib/soft_foundry/*.rb` (the CLI is `cli.rb`, about 95 KB, one `Cli` class dispatching on subcommand strings) and `exe/soft-foundry`; tests are `test/**`; CI is `.github/workflows/ci.yml`.
- `change new` is `Cli#change` `when "new"` (`lib/soft_foundry/cli.rb:292`). It reads `--title`, `--branch`, `--track`, `--scope` and calls `ChangeRecord.create(root, slug, control_plane:, title:, branch:, worktree:, track:, scope:)` (`change_record.rb:19`), which scaffolds from `.ai/templates/change/metadata.yml`. That template carries unset `type` and `risk` lines whose comments list the allowed values (feature, fix, refactor, docs, infrastructure, security, chore; low, medium, high). No `--type` or `--risk` option exists, and no Ruby constant holds those vocabularies; they live only in template comments. Risk values are separately known to `waivable_by_risk` and `tracks.forced_by_risk` in `.ai/workflow.yml`.
- The phase runner (`lib/soft_foundry/phase_runner.rb`) writes the handoff in `begin!` and `finish!` (`finish!` only merges `finished_at`, `exit_status`, `session_id` into `executed_by`). `Cli` calls `finish!` at `cli.rb:1120` (single run) and `cli.rb:1233` (parallel run), then runs `Gate#evaluate`. The gate (`gate.rb:104-115`) fails "no blocking conditions" when a handoff is `complete` with a non-empty `blocking` list, and treats `blocked` with an empty list as a failure of "blocking recorded". Nothing in the runner reconciles the two.
- Invisible characters: the content scan (`content_scan.rb`, README kind table line 140) flags zero-width, bidirectional and tag characters as `invisible`, "error everywhere, never exempt". The scan-allow marker and `.ai/policies/content-scan.yml` exemptions do not apply to that kind. No skill text tells agents how to quote such payloads (visible escapes such as `<U+200B>`, or building them in a script). `adversarial-testing` and `verification` SKILL.md files are short (a few lines) and are the natural homes; the README holds the scan documentation.
- Status output: `Cli#status` (`cli.rb:594`) prints a header line, track, scope, release items, then one gate line per phase and advisories; `status_json` delegates to `Snapshot#change`; `Snapshot#summary`/`board_row` (`snapshot.rb:207+`) already derive per-phase `state` (pass, warn, fail, stale, in_progress, blocked, pending, missing) and `skip_reason`. `ChangeRecord` exposes handoffs, release items, scope. Findings counts live in per-phase handoff `findings:` and review/attack evidence files. There is no short "latest state" view; `status` runs the full gate and prints per-phase check summaries.
- `access_control` is already a repository-profile key: `ControlPlane#access_control` (`control_plane.rb:290`, `declared_globs`), used by `sizing.rb:102` (evaluate/attack sweep every route when a changed path matches), `scope.rb:177` and `check.rb:171` (declaration syntax lint; editing it stales evidence), and documented in README line 326 and `.ai/schemas.md`. The verification template `tests.yml` records `size` and `full_suite` only; it has no field for the state of a protection during the run. `.ai/rules/` has no access-control parity rule (existing rules: accessibility, policy-conformance, security, testing, and others).
- This repository declares no `access_control` globs, no `shared_core`, and `surfaces.application/database/infrastructure/security` are false in this record.

## Inferred
- A parity gate check would sit with the verification checks in `gate.rb` (`Gate.checks_for`, `CHECKS`) and need a harness-eval gate case, following how change A added its size check. Inferred from the existing pattern, not yet designed.
- The latest-state summary can reuse `Snapshot` (`change` hash) rather than re-run per-phase gate summaries; the reuse is inferred from the shape of `board_row`, and whether to run the gate (slower, true) or read recorded handoffs (fast, `recorded_cell`) is a specification decision.
- `ChangeRecord.create` is also used by tests and harness evals; adding `type:` and `risk:` keywords with nil defaults keeps those callers valid.

## Defined by repository policy
- AGENTS.md and `.ai/README.md`: gate and `ci` check structure, never whether claims are true; records without new fields must stay valid; a skill must not perform another skill's job.
- `.ai/rules/accessibility.md` applies because the new summary is CLI output a person reads (`surfaces.accessibility: true`).
- `.ai/policies/` and `.ai/skills/` are not writable by discovery; later phases that edit skill text and a rule file do so under their own skills' permissions (a skill-guidance and rule change is control-plane work and is a decision for specification/plan to route; see unknowns).
- Existing flags and record formats keep working (intake constraint).

## Published policies
Recorded under `policies:` in `.ai/repository.yml` and unchanged: privacy NOT_APPLICABLE (library gem, no user data transmitted), security NOT_APPLICABLE (maintainer decision 2026-09-15; no SECURITY.md exists), terms NOT_APPLICABLE (no service offered). Absence established: no `SECURITY.md`, `PRIVACY*`, or terms file at the repository root. This change touches none of them, so `surfaces.policy` stays false.

## Unknown
See `unknowns.md`.

## Affected components
See `affected-components.md`.

## Dependencies
See `dependencies.md`.
