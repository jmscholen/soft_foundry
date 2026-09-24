# Architecture Review

## Scope reviewed
Where the decision lives (`Guard`), where the answer shape lives (CLI), where the install lives (`Hooks`), and how the guard reuses `ControlPlane#expand`, `ControlPlane.match_any?`, `ChangeRecord#exploring?`, and `track_definition` rather than re-deriving them.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `lib/soft_foundry/guard.rb` | `Guard#decide` returns a `Decision` with no knowledge of modes or exit codes; the CLI turns a decision into an answer. The same decision can be unit-tested without stdin and reused by a future runner. | `.ai/rules/architecture.md` |
| REV-007 | info | `lib/soft_foundry/guard.rb` `active` | The active-skill resolution duplicates the CLI's `current_slug` branch-to-slug logic in a non-raising form. A shared helper on `ChangeRecord` (`for_branch`) would remove the duplicate; follow-up, small. | `.ai/rules/architecture.md` |
| REV-008 | info | `lib/soft_foundry/hooks.rb` | The pre-commit installer and the Claude settings installer share a class but not code; the settings half goes through `SafeWrite` and JSON, the git half writes a script directly. Acceptable: the two targets have nothing in common but the name. | `.ai/rules/architecture.md` |
| REV-009 | info | `Guard.mode` and `Budget.local_settings` | Two three-level resolutions (environment, `.soft-foundry/`, `.ai/policies/`) with the same shape and no shared code. A third would justify a `LocalPolicy` helper. | `.ai/rules/architecture.md` |

## Conformance
Conforms.
