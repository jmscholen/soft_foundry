# Architecture Review

## Scope reviewed
The guard's write branch now taking either a file path or a patch; the hooks module's host-parameterised installer; the runner's shell table and hooked-shell list; the CLI's per-shell warning.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-005 | info | `lib/soft_foundry/hooks.rb` | `install_into(path, matcher)` / `uninstall_from(path)` / `installed_at(path)` replaced two near-identical Claude methods; a third host with the same file shape is one path and one matcher. | `.ai/rules/architecture.md` |
| REV-006 | info | `lib/soft_foundry/phase_runner.rb` | `SHELLS` (how to launch) and `HOOKED_SHELLS` (whether a guard can apply) are separate facts, and the CLI reads both. | `.ai/rules/architecture.md` |
| REV-007 | minor | `Guard#decide` write branch | The branch now resolves paths from two sources then applies three checks to a list; readable, but a `paths_for(tool_name, tool_input)` helper would shorten it. Follow-up. | `.ai/rules/architecture.md` |

## Conformance
Conforms.
