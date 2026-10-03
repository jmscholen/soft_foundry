# Operations Review

## Scope reviewed
Releasing and updating as operations.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-020 | info | releasing | `git tag v<version> && git push origin v<version>`; about a minute later the release exists with the gem. | Operability |
| REV-021 | info | updating | `soft-foundry update --yes` from any directory; a repository behind on `.ai/` is told to run `init`. | Operability |
| REV-022 | minor | rate limits | Unauthenticated GitHub API calls are limited to 60 an hour per address; a 403 is reported as such, and `GITHUB_TOKEN` lifts it. | Operability |

## Conformance
Conforms.
