# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase; review and attack are not independent, and the advisory says so for review.
- The direction was the maintainer's choice among three offered (all repositories; one repository clearly labelled; one repository with the rest hidden), after two earlier misreadings in this line of work. The choice was asked for, not assumed.
- Stacked on `ui-processes`, which finds the sessions this change turns into repositories.
- The token was offered with the all-repositories option because the server's reach grows; earlier reviews had recorded the missing authentication as an accepted risk to revisit.
- Lesson applied from `ui-processes`: the evaluation was run against the maintainer's real machine (four repositories, five sessions) before anything was called done, and found two faults a staged run had not.

## Ambiguities resolved
- How a repository is named in an address: a 12-character id derived from its path and issued by the server. A path in a request would turn the server into a reader of any directory.
- Whether a repository disappears when its last session closes: no, for the life of the server, so a page open on it keeps working.
- Where the token travels: in the link's fragment, then in a request header. Not in a query string (it would reach logs and the Referer) and not in a cookie (it would ride along on requests the page did not make).
- Top navigation: Repositories and Running. Changes and Workflow belong to a repository and move into its bar.

## Ambiguities that block safe progress
None.
