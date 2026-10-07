# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Lock a sibling `sessions.jsonl.lock`, write a temporary file, rename over the ledger | Lock and rewrite the ledger in place | A rename replaces the inode, so a lock on the ledger itself would let a waiter rewrite the old file; in-place rewriting risks a half-written ledger on a crash | Readers never lock and always see a whole file |
| Keep a line that does not parse, verbatim | Drop it | The ledger is the person's data; a bad line must not silently disappear | Corrupt lines persist until the person removes them |
| Grok detected by the camelCase `hookEventName` key | Trust the `--shell` flag | Grok runs Claude's settings hooks too, so the flag says `claude` | A future Claude payload adding that key would be misfiled; checked live that Claude's does not today |
| One hook entry per agent file, each naming its shell; Grok's own file under `~/.grok/hooks/` | Rely on Grok reading `~/.claude/settings.json` | A person may turn Grok's Claude compatibility off | A Grok prompt may record twice; the upsert makes that harmless |
| `--name <slug>/<phase>` for Claude Code runs | `slug · phase` | The dry-run prints arguments shell-escaped; a slash needs no escaping | Session names read `ui-links/review` |
| Doctor reports the session hook as `! warn` when absent, never `fail` | A pass/fail check | The hook is optional; doctor's exit code must not change for it | One doctor line uses `warn`; the status-word test now allows it |
| Snapshot carries absolute paths only in `recorded_sessions` | Repository-relative paths | A resume command must `cd` to the real folder | Documented in the method comment; the page is loopback-only and token-gated |
