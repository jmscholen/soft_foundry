# Rollback

- `soft-foundry hooks uninstall --sessions` removes the user-level hook entries and the skill files Soft Foundry wrote; `rm ~/.soft-foundry/sessions.jsonl` removes the ledger.
- Reinstalling 0.17.1 restores the previous behavior; the guard then again lets Grok calls through as unguarded.
