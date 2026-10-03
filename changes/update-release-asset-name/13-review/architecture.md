# Architecture Review

## Scope reviewed
`Updater.gem_command`, the downloader's signature.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-004 | info | `gem_command` | One place names the gem command; both subprocesses use it. | Single source |

## Conformance
Conforms.
