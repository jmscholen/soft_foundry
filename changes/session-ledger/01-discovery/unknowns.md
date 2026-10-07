# Unknowns

| Unknown | Impact if wrong | How to resolve | Blocking? |
| --- | --- | --- | --- |
| Codex's `UserPromptSubmit` payload fields at 0.139.0 (documented as `session_id`, `cwd`, `prompt`, `transcript_path`) | Codex rows missing a field; the logger tolerates absent fields | Live Codex turn once its login is renewed; recorded as unverified in evaluation | no |
| Whether `codex exec` fires `UserPromptSubmit` (the runner's Codex session lookup depends on it) | `executed_by.session_id` stays null for Codex runs | Same live check; the runner degrades to null | no |
| Whether Grok deduplicates the Claude-settings hook and its own hook | One prompt recorded twice; harmless because recording is an idempotent upsert | Covered by design | no |
