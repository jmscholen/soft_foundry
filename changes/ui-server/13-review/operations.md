# Operations Review

## Scope reviewed
How the command behaves as a running process: start, stop, failure, cost.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-030 | info | `CLI#ui` | Starts in under a second, prints its URL, stops on SIGINT or SIGTERM with exit 0, and names the fix for each refusal. | Operability |
| REV-031 | minor | `UI::Server` | It logs nothing after the first line. A refused or failed request is visible only to the client. A `--verbose` request log would help when the page says "Not connected". | Observability |
| REV-032 | minor | cost | See REV-002: CPU while a tab is visible grows with the number of open records. A hidden or paused tab costs nothing. | Bounded operational cost |
| REV-033 | info | port | Defaults to a free port, so two repositories can be served at once; `--port` pins one for a bookmark. | Operability |

## Conformance
Conforms.
