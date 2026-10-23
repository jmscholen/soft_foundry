# Implementation Log

## Changes made
Ruby standard library only; no new gem. Each slice is a RED commit (the failing tests) followed by a GREEN commit (the code), so verification can bind `red_commit` to the first of each pair.

| Slice | RED | GREEN | What it adds |
| --- | --- | --- | --- |
| 1 Foundations | 053562b | 5d653e6 | `RecordLock` (flock under `.soft-foundry/locks/`, 10 s bound, reentrant, symlink-refusing); `ChangeRecord#update_metadata`, `#update_handoff`, `#transaction` (stage every file, rename metadata first, remove staged files on failure); `released?`, `finished?`, `release_items`, `open_release_items`; `Text.free_text!`, `Text.id!`, `Text.env_name!`; `SafeWrite.stage`/`commit_staged`; `PhaseRunner#begin!`/`finish!` rebuilt on the helpers. |
| 2 Phase reopen | 8e3c940 | 9812469 | `ControlPlane#downstream`; `PhaseReopen`; `phase reopen <phase> --reason TEXT [--change SLUG]`; `phase_reopenings` history with `previous`; output prefix `phase reopen:`. |
| 3 Auto-reopen | 320322a | 2a5d718 | A complete phase whose gate reports "evidence current" failed is reopened (source auto, reason names the check and stale commit) and then run; `--dry-run` prints `would reopen` / `would reset`. |
| 4 Marker and guard | ed4d4be | 063075a | `SOFT_FOUNDRY_PHASE` set by the runner for single, parallel and panel sessions; `PhaseRunner::Launch#env` (inspect names variables only); guard resolves the skill from the marker and treats a bad, unknown or non-isolated marker as a violation; `ControlPlane#isolated_phases`; `check` lints `isolated_phases`. |
| 5 Parallel | b04c813 | 3e07ac0 | `phase run A B --parallel [--env NAME=VALUE]...` (`ParallelRun`); pre-flight refusals before any write; per-phase `{phase}` expansion; `warn:` without `--env`; start HEAD told to sessions with a do-not-commit instruction; HEAD-moved warning; per-phase `phase <id>: pass|fail` and a `parallel:` summary; TERM forwarded to every child on INT/TERM; `current_phase` set to the first phase not complete. |
| 6 Released | 31d72d1 | 1be5975 | `Release` (`change release --item ID=DESC`, `change discharge ID --note TEXT`), `ChangeRecord#judgment_outcome`, `change close` on a released record, `ci` branch, `merged_unclosed?`, `check` lint of the release block. |
| 7 Consumers of `closed` | 044f2b9 | d2050f6 | `scope` (released claims nothing), `snapshot` (board, overview, change, timeline events for phase reopens, release, discharge), `ps` table, `learn promote`, `change reopen`, `change status`, harness-eval `STATUSES`, UI board section, release items table, usage text. |

Full suite with provider keys unset at d2050f6: 781 runs, 6022 assertions, 0 failures, 0 errors. `soft-foundry check` and `soft-foundry eval` pass. No existing test file was edited.

## Decisions
See decisions.md.

## Deviations from plan
See deviations.md. The one that matters most: the plan's slice 8 (`.ai/` control plane, README, `docs/`, harness-eval cases) is outside what the implementation skill may write, so it is not done; the exact text owed is in owed-control-plane-and-docs.md.

## Challenges
- The runtime guard parses the text of a shell command, so a heredoc that mentioned a protected path or a glob over `changes/` was refused. Test and library files were written with the file tools instead. No workflow impact.
- Reading the existing `phase_runner_test.rb` and `factory_readiness_test.rb` showed a complete-but-stale phase is already runnable (`refusal` returns nil for it), which the plan describes as a refusal to be replaced. The default of `refusal` was therefore left alone (deviation D4).
