# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: what the guard reads from a patch (paths, never content) and what the installer writes.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-015 | info | `Guard#patch_paths`, the hook file | Header paths only; nothing about a person; nothing transmitted. | Rule: data minimisation |

## Policy text changes required
None.

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
