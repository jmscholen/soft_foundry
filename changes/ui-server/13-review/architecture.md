# Architecture Review

## Scope reviewed
Dependency direction, the split between deciding and doing in the server, and what the page knows.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-007 | info | `UI::Server` | Depends on `Snapshot`, `ChangeIndex`, `ControlPlane`, `Git`; nothing in the domain depends on it. `respond` decides from three values and touches no socket. | "Domain behavior should not depend directly on delivery mechanisms" |
| REV-008 | info | `soft_foundry.gemspec` | No dependency added. The hand-written parser is about 60 lines and handles only what the page needs. | `.ai/rules/dependencies.md` |
| REV-009 | minor | `app.js` | State words, skip reasons, and which states count as failing are restated in the page (`STATES`, `run`, `defaultGate`). The server could send the words; the page would then only draw. Acceptable at this size. | Single source of truth |
| REV-010 | info | `lib/soft_foundry/ui/assets/` | Packaged with the gem, outside `.ai/`, so nothing is copied into adopter repositories. | Installer boundary |
| REV-011 | minor | `snapshot.rb` | This change edits a file introduced by the change it is stacked on. The edit is a remediation and is small, but it means `ui-snapshot` must merge first and unchanged. | Stacked changes |

## Conformance
Conforms.
