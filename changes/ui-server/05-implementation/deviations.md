# Deviations From Plan

1. Cross-site refusal narrowed. The plan and the RED test refused any request with `Sec-Fetch-Site` other than `same-origin` or `none`. The first browser run showed this also refuses the page itself when it is opened from a link or by browser automation (a cross-site navigation). The page's three files carry nothing about the repository, so the check now applies to the data routes only, and the RED test was rewritten at GREEN to assert both halves. Affects REQ-UI-003. No weakening of what is protected: the data.
2. `%zz` in a query. The RED test expected a 400; Ruby's `URI.decode_www_form` does not raise on it. The server now rejects an invalid percent-escape itself, so the test passes as written.
3. Remediation inside this change. The attack phase found two defects after GREEN; they were fixed test-first (`ae60e88`, `5d36e6f`) and every commit-bound phase is recorded at `5d36e6f`. One of the fixes is in `lib/soft_foundry/snapshot.rb`, which belongs to the change this one is stacked on; that record's evidence is measured on its own branch and is unaffected.
4. Connection limit. The plan said requests run "to completion on a single thread". A thread per connection replaced it before RED, for the reason in `decisions.md`.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it. The maintainer approves these by merging.
