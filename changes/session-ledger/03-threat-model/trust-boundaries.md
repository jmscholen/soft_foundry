# Trust Boundaries

| Boundary | Trusted side | Untrusted side | Crossing |
| --- | --- | --- | --- |
| Hook payload | Soft Foundry's session-log command | The agent process and anything that shaped the payload: the prompt text, the folder name, a repository's branch names and change records | JSON on stdin, once per prompt |
| Ledger file | The user who owns `~/.soft-foundry/` | Any other local user or process | File system permissions (0700 directory, 0600 file) |
| Printed resume commands | The person who pastes them | Every field that came from a payload | Shell quoting; session-ID validation |
| Terminal and browser rendering | The person reading `sessions` output or the UI | Prompt excerpts, folders, branches | Control-character stripping; the UI's text-only rendering |
| User-level agent configuration | The person's existing settings | Soft Foundry's installer | Marker-scoped edits through `SafeWrite`; symlinks refused |
| Guard decision | The skill's permissions | A Grok tool call | Tool-name mapping |
