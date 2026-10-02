# Operations Review

## Scope reviewed
Cost with several repositories, and what running it is like now.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-028 | info | cost | The home page with four real repositories answered in about 0.4 s (a process listing plus four overviews), reused for 2 s. A repository's board costs what it did before, only when opened. | Bounded cost |
| REV-029 | minor | the link | It changes every run and cannot be bookmarked; a new tab needs it again. A stable token from a local, gitignored file would trade some secrecy for convenience. | Operability |
| REV-030 | minor | restart | The registry is in memory. After a restart, a repository with nothing running is gone until named with `--repo`. | Operability |
| REV-031 | info | one server | One `soft-foundry ui` now covers the machine; running a second one elsewhere works and shows the same repositories from a different home. | Operability |

## Conformance
Conforms.
