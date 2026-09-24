# Security Review

## Scope reviewed
A new parser on untrusted input (patch text from a coding session), a new hook file written to the repository, and the trust step Codex imposes.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-008 | info | `Guard#patch_paths` | Paths are taken from header lines only and passed through `relative`, so `../x` and `/etc/x` in a header are refused as outside the repository, and a path in a denied group is refused whichever header names it, including a move target. | `.ai/rules/security.md` |
| REV-009 | info | `.codex/hooks.json` | Written through `SafeWrite`; symlinks and non-object JSON refused, like Claude's settings. Committed to this repository on purpose, as the Claude one is. | `.ai/rules/security.md` |
| REV-010 | minor | Codex trust | A committed `.codex/hooks.json` does nothing until the person trusts it in Codex; a clone that skips `/hooks` runs unguarded while `doctor` reports the hook installed. The install output and README say so; `doctor` cannot see Codex's trust store. Stated scope. | `.ai/policies/human-boundaries.yml` |
| REV-011 | info | Grok | No hook surface exists, so under Grok every permission is policy; the runner says it on every launch rather than once in the docs. | `AGENTS.md` |

## Conformance
Conforms, with REV-010 stated as the design's honest scope.
