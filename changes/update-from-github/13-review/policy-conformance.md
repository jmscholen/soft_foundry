# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: the outbound calls. The profile's privacy rationale says "the only outbound calls are provider model listings and the RubyGems version check"; the version check now goes to api.github.com and github.com instead, and sends `GITHUB_TOKEN` if the environment has one.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-016 | minor | `.ai/repository.yml` privacy rationale | Still names RubyGems as the version check's destination. True in spirit (one outbound check), wrong in detail; a one-line follow-up edit to the profile. | Rule: say what is sent where |

## Policy text changes required
None (no published policy).

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
