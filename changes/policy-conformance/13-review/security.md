# Security Review

## Scope reviewed
New file reads: `Advisory` reads `metadata.yml`, phase handoffs, `requirements.yml`, `policy-conformance.md`, and `.ai/repository.yml`; `MaturityScan#policy_documents` lists basenames in a fixed set of directories and never opens the files; `change new` rewrites two lines of the `metadata.yml` it just created. No network, no credentials, no environment variables beyond what already existed.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | `lib/soft_foundry/maturity_scan.rb` `policy_documents` | `Dir.glob` with `FNM_DOTMATCH` over one level of fixed directories; entries are filtered with `File.file?`, which follows symlinks, so a symlink named `PRIVACY.md` records its repository-relative path as evidence and nothing else. Contents are never read. Paths recorded in the profile stay repository-relative. | `.ai/rules/security.md` (path handling) |
| REV-010 | info | `lib/soft_foundry/advisory.rb` `human_decisions` | A decision is free text in a file anyone with write access to the record can edit; the advisory can tell a filled entry from a placeholder, not a person from an agent. Same trust model as `change close --confirm`: the record is where a decision is written down, and the pull request is where it is checked. The `never_autonomous` list in `human-boundaries.yml` (fabricating evidence) governs the agent side. | `.ai/policies/human-boundaries.yml` |
| REV-011 | info | advisory messages | Messages interpolate the document names from the profile (`privacy`, `security`, `terms`, filtered to the known three) and the skip rationale from `metadata.yml`; no file paths from the scan reach the terminal through the advisory. | `.ai/rules/security.md` |

## Conformance
Conforms. No new attack surface beyond what `metadata.yml`'s threat_model rationale records.
