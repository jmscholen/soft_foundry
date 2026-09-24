# Security Review

## Scope reviewed
The guard is a security control, so the review asks how it fails. Inputs: a JSON payload on stdin from the coding shell; the branch name; the change record; `.claude/settings*.json` on install; the environment variable. Outputs: an exit code, stderr, an append to `.soft-foundry/guard.log`, and on install a rewritten settings file.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-010 | info | `lib/soft_foundry/cli.rb` `guard` | Fails closed in block mode on anything it cannot parse; every exception path inside `decide` (a bad record, an unknown skill) resolves to a `Decision` rather than a raise. A crash would surface as exit 1 from the CLI's rescue, which Claude Code treats as a non-blocking error; that is the one path that fails open, and it requires the guard itself to be broken. | `.ai/rules/security.md` |
| REV-011 | info | `lib/soft_foundry/guard.rb` `relative` | Paths are expanded against the root before matching, so `lib/../.ai/rules/x.md` matches `.ai/**`, not `lib/**`; a path outside the root keeps its leading `/` or `..` and is refused for writes. Symlinks inside the repository are not resolved: a symlink under `lib/` pointing at `.ai/` would be allowed for writes. The same is true of the gate's staleness check and of git itself; follow-up to `realpath` when the target exists. | `.ai/rules/security.md` |
| REV-012 | info | `lib/soft_foundry/hooks.rb` `read_settings` | Refuses a symlinked settings file, refuses non-object JSON, and writes through `SafeWrite` (exclusive temp file, no follow). A planted `.claude/settings.json.soft-foundry-tmp` is refused rather than overwritten. | `.ai/rules/security.md` |
| REV-013 | info | `.soft-foundry/guard.log` | Log lines interpolate paths and the skill name from the record; no shell is involved and the file is gitignored and machine-local. A path containing a newline would split a log line; cosmetic. | `.ai/rules/security.md` |
| REV-014 | minor | trust model | The guard reads the mode from a file the agent may be able to write (`.soft-foundry/enforcement.yml` is outside every path group) and from the environment. An agent that wants to disable the guard can. This is the same trust level as every hook in the host: the guard stops mistakes and drift, not a determined agent; the host's own permission system is the layer for that. Stated in the README. | `.ai/policies/human-boundaries.yml` |

## Conformance
Conforms, with REV-014 stated as the control's honest scope.
