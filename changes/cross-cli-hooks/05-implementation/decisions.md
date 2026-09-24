# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Parse apply_patch headers in the guard rather than adapt field names | A translator hook that rewrites the payload into Claude's shape | Codex sends no file path for an edit; the paths only exist inside the patch text, so a translator would need the same parser | `patch_paths` in the guard; `Edit`/`Write` with a `command` and no file path are read as patches |
| One installer for both hosts, parameterised by path and matcher | A separate Codex installer | The hook file shape is identical; only the file and the tool names differ | `install_into` / `uninstall_from` / `installed_at`; the Claude methods delegate |
| Say the Codex trust step at install time | Assume the person knows | A hook that silently never runs is worse than no hook; the README and the installer both name `/hooks` | One extra output line on `--codex` |
| `--local` is refused with `--codex` | Ignore it; write `hooks.local.json` | Codex documents one project-scope file; inventing a second would mislead | A one-line `TargetError` |
| One doctor line for both hosts | A line per host | Every doctor line must carry a status word, and a repository using one host must not fail on the other | `guard hook (claude: ..., codex: ...; mode: ...)` |
| Grok is in the runner but not in `HOOKED_SHELLS` | Leave Grok out until it has hooks | A fresh session is still worth having; the warning states the limit | `grok -p [extra] <prompt>`; a `! warn guard:` line every launch |
| Promote control-plane-scan's two 0.85 instincts here | Wait | The governance path is meant to be routine | Two more sections in `learned.md`; the fixture reset from the previous change keeps the tests honest |
