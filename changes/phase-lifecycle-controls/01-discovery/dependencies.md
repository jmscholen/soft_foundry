# Dependencies

## Internal dependencies
- `Gate#evaluate(phase).stale?` (`gate.rb`, "evidence current" check, scoped by `scope.rb`) decides staleness; auto-reopen depends on it and must not change its meaning.
- `ControlPlane`: `phases`, `successor`, `predecessor`, `effective_predecessor`, `transitions`, `hardening_phase?`, `panel_phases` (precedent for a workflow-declared phase list). `workflow.yml` `transitions` and the comment "any transition back to verify marks verify, evaluate, attack, review, and judge evidence stale" define downstream.
- `ChangeRecord`: `handoff`, `phase_status`, `reached_lifecycle_end?`, `finished_commit_sha`, `undischarged_acceptance`, `close!`, `reopen!`; `ChangeIndex#merged_unclosed?`.
- `Guard` reads `metadata.yml` `current_phase` and environment markers set for panel members; `PhaseRunner#begin!` writes `current_phase`.
- `Snapshot`, `Processes`, `Scope`, `Check`, `HarnessEval` (statuses), and `ui/` consume status and history keys.
- `Panel` / `spawn_panel`: existing concurrent child spawn with per-child environment.

## External services and libraries
- Ruby standard library only (`yaml`, `time`, `securerandom`, `shellwords`, `Process.spawn`); the Gemfile adds minitest and rake. No network service is involved. The coding-shell executables (`claude`, `codex`, `grok`) are launched by `phase run`; their behaviour is not changed.
- The adopter's own per-run state (for example a `DATABASE_URL`) is provided by the adopter; Soft Foundry only passes a value through (request constraint).

## Infrastructure dependencies
N/A. GitHub Actions runs `soft-foundry ci` and the test suite on `main`; `released` changes how `ci` treats a merged record.
