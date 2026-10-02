# Functional Review

## Scope reviewed
The server's registry, token, and routes; the additions to `processes.rb`, `snapshot.rb`, and `cli.rb`; the restructured page; the tests; the evaluation and attack evidence; against REQ-REPO-001..008.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Each requirement is implemented, with server and data tests and a browser pass on the real machine. | REQ-REPO-001..008 |
| REV-002 | major | `app.js` | Two faults reached a GREEN-ready tree and were caught only by using the page: a shadowed helper that stopped the Running view, and a token link ignored in an open tab. The page still has no automated test that runs it, and it is now about 900 lines. This has been a minor finding in four records; it is no longer minor. | `.ai/rules/testing.md` |
| REV-003 | minor | `app.js` `load` | A fault while drawing is reported to the person as "Not connected". The console now says what happened, but the page does not. | REQ-REPO-008, error identification |
| REV-004 | minor | home page | A repository's open changes show recorded status; a failing or stale gate is not visible until the repository is opened. | REQ-REPO-001 |
| REV-005 | minor | registry | A repository named with `--repo` or found once stays listed even if its directory is later deleted; its card then shows an error. | REQ-REPO-004 |
| REV-006 | minor | `UI::Server#repositories` | Calls `running` itself, so the home page pays for a process listing that the page also requests separately; both are cached for 2 s but under different keys. | Efficiency |
| REV-007 | info | old addresses | `#/change/<slug>` and `#/workflow` still resolve to the server's own repository. | REQ-REPO-002 |

## Conformance
Conforms, with REV-002 as the finding that most needs a follow-up change.
