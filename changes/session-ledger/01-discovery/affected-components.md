# Affected Components

| Component | Path | Why affected | Confidence |
| --- | --- | --- | --- |
| Guard | `lib/soft_foundry/guard.rb` | Grok tool names (`write`, `search_replace`, `read_file`, `run_terminal_command`) and `target_file` | discovered |
| Hook installer | `lib/soft_foundry/hooks.rb` | User-level session hook for three agents and the find-session skill | discovered |
| Session ledger (new) | `lib/soft_foundry/session_ledger.rb` | Record, lock, mask, search, resume command | inferred |
| CLI | `lib/soft_foundry/cli.rb` | `session log`, `sessions`, `resume`, `hooks install --sessions`, `doctor` line, help | discovered |
| Phase runner | `lib/soft_foundry/phase_runner.rb` | Session IDs per shell, `executed_by.session_id`/`cwd`, Grok in hooked shells | discovered |
| Snapshot and UI | `lib/soft_foundry/snapshot.rb`, `lib/soft_foundry/ui/assets/app.js` | Recorded sessions on a change's page | discovered |
| Documentation | `README.md`, `.ai/schemas.md` | New commands, ledger contents, `executed_by` fields | discovered |
| Repository profile | `.ai/repository.yml` | Privacy rationale now names what is stored locally | discovered |
