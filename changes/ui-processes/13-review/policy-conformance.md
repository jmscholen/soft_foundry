# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: what is read (the current user's process table and working directories), what is kept (nothing), and where it goes (stdout or the loopback page). No outbound request is added.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-021 | info | `Processes` | Reads only the invoking user's own processes and reports a few fields about those that are soft-foundry. Nothing is stored or transmitted off the machine. | Rule: data minimisation |

## Policy text changes required
None.

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
