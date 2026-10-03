# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| One page for all repositories | One repository, labelled; one repository, others hidden | The maintainer's choice, after the two scopes on one page confused them | The server reads repositories it was not started in |
| Repositories are found by what is running, plus `--repo` | Scan the disk; a config file of repositories | What is running is what the person wants to see, and it needs no setup | A repository with nothing running is absent unless named |
| A found repository stays for the server's life | Drop it when its last session closes | A page open on it must keep working | The list only grows until restart |
| Issued hex ids in addresses | Paths; directory names | A path in a request is a file-read primitive; names collide | Links are not readable or stable across machines |
| Token in the fragment, then a header | Query string; cookie; no token | The fragment is not sent or logged; a header cannot be sent cross-origin without a preflight; a cookie rides on requests the page did not make | The link must be opened once per tab; a bare address shows an explanation |
| Session storage for the token | Memory only; local storage | Survives a reload in the same tab, ends with the tab, is not shared with other tabs or kept on disk across restarts | A new tab needs the link again |
| The page's files need no token | Token for everything | They say nothing about any repository, and a bare address must be able to explain itself | The shell of the page is readable by anything local |
| Top navigation is Repositories and Running; Changes and Workflow sit in a repository bar | Keep four top links with a repository switcher | Two levels that match the two scopes: the machine, then one repository | Addresses changed; the old ones still work for the home repository |
| The overview does not gate | Gate every open change on the home page | Gating costs about 0.4 s per open record per repository | The home page shows recorded status and phase; gates are a click away |
