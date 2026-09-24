# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change, so the question is whether that is right: does the change alter anything Soft Foundry itself collects, shares, retains, protects, or promises? Examined: the guard log (what it records, where it lives), the settings file write, and the payload read.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-019 | info | `.soft-foundry/guard.log` | The log records timestamps, tool names, repository-relative paths, the skill, and the reason. No content of any file, no command text beyond the paths it named, nothing about a person. Machine-local and gitignored; retained until the person deletes it. | Rule: classify every new data element; data minimisation |
| REV-020 | info | `lib/soft_foundry/cli.rb` `guard` | The full hook payload (which for Bash includes the command text) is parsed and discarded; only the decision is kept. Nothing is transmitted anywhere. | Rule: data minimisation |

## Policy text changes required
None. This repository publishes no privacy policy, security policy, or terms, so there is no text to change.

## Conformance
N/A, with the statement above of what was examined: the change alters nothing Soft Foundry collects, shares, retains, protects, or promises beyond a machine-local log of paths, and `surfaces.policy: false` is correct.
