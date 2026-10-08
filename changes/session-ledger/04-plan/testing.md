# Testing Plan

- Unit and CLI tests per AC as listed in `implementation.md`, run with `bundle exec rake test` (or `ruby -Ilib -Itest`), and once more with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and `SOFT_FOUNDRY_BILLING` unset because the machine exports them.
- Concurrency (AC-006): 20 forked processes against one ledger.
- Performance (AC-014): a generated 5,000-entry ledger, one CLI `session log` timed end to end.
- No test touches the real home directory: every ledger path and HOME is a temporary directory.
- Evaluation drives the installed hook for real: Claude Code (`claude -p`) and Grok (`grok -p`) with a temporary HOME-scoped install where the CLI allows, else a scratch settings file; Codex only as far as its expired login allows.
- `soft-foundry ci` and `soft-foundry check` against this repository.
