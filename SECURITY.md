# Security policy

Soft Foundry is a developer tool. It is not a hosted service and does not
collect user data. It does have a trust surface:

- `soft-foundry init` writes files into a target repository, including
  `.ai/` policy and `AGENTS.md`.
- `soft-foundry hooks install` installs a PreToolUse hook into
  `.claude/settings.json` or `.codex/hooks.json`.
- `soft-foundry guard` can allow or refuse an agent's file and shell tool
  calls. Default mode is `warn` (report and allow). `block` refuses.
- `soft-foundry update --yes` installs a gem from RubyGems.
- `soft-foundry phase run` and `--maturity=deep` launch a coding shell.

## What the guard does and does not enforce

| Surface | Enforced? |
| --- | --- |
| Edit / Write / MultiEdit / NotebookEdit / Codex `apply_patch` vs a skill's write and deny_write sets | Yes |
| Read vs deny_read | Yes |
| Bash vs deny sets, only when the command text names a denied path | Partial |
| What a Bash command actually writes | No — policy only |
| Grok (no hook mechanism) | No — policy only |
| Tool calls outside a live change branch | No |

`soft-foundry doctor` prints the mode in effect. A machine may override
repository policy with `.soft-foundry/enforcement.yml` or
`SOFT_FOUNDRY_GUARD=warn|block|off`.

## Reporting a vulnerability

Open a GitHub issue on [jmscholen/soft_foundry](https://github.com/jmscholen/soft_foundry)
if the finding can be discussed in public (a hook bypass with no exploit
payload, a path-escape in the installer). For a finding that includes a
working exploit against the guard or installer, email the maintainer
listed on the GitHub profile and do not attach secrets or customer data.

Please include Soft Foundry's version (`soft-foundry version`), the host
shell (Claude Code, Codex, Grok, none), and a reproduction that does not
require production credentials.
