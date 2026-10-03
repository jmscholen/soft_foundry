# Functional Review

## Scope reviewed
`updater.rb`, the `update` command, the release workflow, the profile edit, the tests, and the transcripts, against REQ-UPD-001..006.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Each requirement is implemented and tested; the source-build path and the check ran for real. | REQ-UPD-001..006 |
| REV-002 | major (evidence gap) | release | The attached-gem path and the workflow have run only in tests. The first tag is the real test and should be watched. | REQ-UPD-002, REQ-UPD-003 |
| REV-003 | minor | `Updater#real_download` | No injected seam, so redirects and the token rule are untested (ATTACK-003). | `.ai/rules/testing.md` |
| REV-004 | minor | `update --yes` | A pre-release or draft is not distinguished: `releases/latest` excludes them by GitHub's rule, which is what is wanted, but nothing here says so. | REQ-UPD-001 |
| REV-005 | minor | `init` hint | Compares the manifest's version string with the release's; a repository with no manifest (older install) gets no hint. | REQ-UPD-004 |

## Conformance
Conforms, with REV-002 to be closed by the first real release.
