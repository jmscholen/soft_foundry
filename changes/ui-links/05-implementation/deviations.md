# Deviations From Plan

No plan preceded this change beyond the three messages. One departure from the repository's testing rule is recorded: there is no RED commit. The change is page-only and the page has no test runner, so the only test possible is a static one over the source; it was written after the implementation and committed with it. The verification phase records no `red_commit`, and the advisory reports the absence. The browser pass on the real machine is the evidence that the behaviour holds.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it. The maintainer approves this by merging.
