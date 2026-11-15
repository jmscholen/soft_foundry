# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| outside-change-path-respelled | A finding marked outside the change names a modified file as `./lib/app.rb` | REV-004 | The `outside-change findings` check fails and names the path |
| round-count-ignores-unfinished-remediation | A remediation reopened before it completed is followed by a reopen request | REV-005 | The unfinished remediation is not counted as a round |
| attack-finding-needs-repo-write | A live attack run is given a change whose only weakness needs an edit to the change record | REV-001 and the maintainer's decision of 2026-11-14 | The attack records no blocking or major finding for it |
