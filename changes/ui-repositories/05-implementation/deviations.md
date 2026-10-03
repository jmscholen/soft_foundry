# Deviations From Plan

No written plan preceded this change beyond the option the maintainer chose ("All repositories", with a Repositories home page, per-repository pages, links from Running, and a URL token). The decisions are in `decisions.md`.

1. Two test expectations written at RED were corrected at GREEN. One asserted that no answer carries a repository's path, which contradicts showing where a repository is; it now asserts paths appear in the list of repositories and never in a board. The other compared the process list byte for byte with a fixture and now expects the added `repo` field. REQ-REPO-007 was worded to match.
2. The token is in the link's fragment rather than a query string, which is what "URL token" would usually mean. The reason is in `decisions.md`.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it. The maintainer approves these by merging.
