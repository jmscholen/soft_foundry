# Repository Context

## Discovered
- Ruby gem (`soft_foundry` 0.17.1), standard library only, minitest suite under `test/`, executable `exe/soft-foundry`, CI in `.github/workflows/`. Layout unchanged since the prior changes (`changes/ui-repositories`, `changes/update-from-github`).
- Hook installation lives in `lib/soft_foundry/hooks.rb`: the guard entry is written to repository-level `.claude/settings.json`, `.claude/settings.local.json`, or `.codex/hooks.json` through `SafeWrite`, recognized by the `soft-foundry:guard` marker in its command, refusing symlinked targets. Nothing writes user-level configuration today.
- The guard (`lib/soft_foundry/guard.rb`) maps tool names to decisions: `Edit Write MultiEdit NotebookEdit apply_patch` as writes, `Read` as reads, `Bash` as shell; any other name is allowed as "not guarded" (`decide`, the `else` branch).
- The phase runner (`lib/soft_foundry/phase_runner.rb`) launches `claude -p`, `codex exec`, or `grok -p`; `HOOKED_SHELLS` is `claude codex`; `executed_by` holds `runner shell fresh_context started_at finished_at exit_status previous_phase`.
- Live state: `lib/soft_foundry/processes.rb` lists running `soft-foundry` commands and open coding shells from `ps`; `lib/soft_foundry/snapshot.rb` and `lib/soft_foundry/ui/` serve it read-only on loopback. The UI already calls open shells "sessions" (`sessionsFor` in `app.js`).
- `lib/soft_foundry/content_scan.rb` holds `SECRETS`, the secret-shape patterns the control-plane scan uses.
- Installed CLIs and their session facts are recorded in `00-intake/assumptions.md` (Grok checked live; Claude Code from its help; Codex's `thread.started` event checked live, the rest from documentation because its login has expired).

## Inferred
- A user-level hook is a new kind of write for Soft Foundry (outside any repository); it should reuse `SafeWrite` and the same marker-based replace/remove so reinstalling is idempotent.
- The ledger must use the UI's word "sessions" carefully: open shells are already "sessions" there; recorded ones need a distinct label.

## Defined by repository policy
- `.ai/rules/accessibility.md`: every output line states its outcome as a word.
- `.ai/rules/security.md` and the guard's own contract: the guard never weakens; exemptions go in policy with a reason.
- Machine-local state stays out of committed records (`.ai/repository.yml` header; `.soft-foundry/` is git-ignored).

## Published policies
Soft Foundry publishes no privacy policy, security policy, or terms; `.ai/repository.yml` records all three `NOT_APPLICABLE` with rationale (security by maintainer decision on 2026-09-15). This change makes the privacy rationale's last clause untrue once the session hook is installed: the ledger stores prompt excerpts, folders, and branch names on the user's own disk. Nothing is transmitted and no service exists, so the status stays `NOT_APPLICABLE`; the rationale is updated in `.ai/repository.yml` by this discovery phase to say what is stored locally.

## Unknown
See `unknowns.md`.

## Affected components
See `affected-components.md`.

## Dependencies
See `dependencies.md`.
