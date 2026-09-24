# Architecture Review

## Scope reviewed
`ContentScan` as a module of pure functions over text and paths; three callers (`Check`, `Gate`, the CLI) that only format; the allowlist beside the other policies.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `lib/soft_foundry/content_scan.rb` | `scan_text` is pure (text in, findings out); `scan_paths` adds file reading and the allowlist; the three callers differ only in which paths and how findings are printed. | `.ai/rules/architecture.md` |
| REV-007 | info | `ContentScan.allowed?` | Reuses `ControlPlane.match_any?` for path globs, so allowlist paths behave like every other glob in the control plane. | `.ai/rules/architecture.md` |
| REV-008 | minor | `Check#check_content` and `CLI#scan` | Both format a finding as `path:line kind: detail`; a `Finding#to_s` would remove the duplicate. Follow-up. | `.ai/rules/architecture.md` |

## Conformance
Conforms.
