# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| Guard configuration | `.ai/policies/enforcement.yml`, the hook entries in `.claude/settings*.json` and `.codex/hooks.json`, the machine-local `.soft-foundry/enforcement.yml`, `SOFT_FOUNDRY_GUARD` | every skill's tool calls | MIT-001: writes and shell mentions refused in every skill; the variable is the maintainer's shell, not a tool call |
| Harness evals | `.ai/harness-evals/**` | every skill (read and write) | existing `deny_read` lint and protected write set; MIT-003 |
| Scratch repository | the temp directory one eval case runs in | the host repository, the home directory | MIT-002 path validation; MIT-006 removal |
| Live eval session | a coding shell launched by `phase run` in the scratch repository, as the user | the host repository and the user's credentials | the session's own permission mode, as `phase run` already relies on; the scratch repository is the only tree it is asked about; documented limit (no OS sandbox, the panel-phases residual) |
| Change record waivers | `skipped_phases` and `risk` in `metadata.yml` | the gate, `change close` | MIT-004 |
| Specification | `02-specification/` after the specify phase completes | every later phase | permissions (existing), MIT-005 |
| Output | `eval`, guard, gate lines a person or CI reads | case content, planted secrets | MIT-007 |
