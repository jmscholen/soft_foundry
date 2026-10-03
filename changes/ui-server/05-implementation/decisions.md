# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Hand-written server on `socket` | `webrick` as a runtime dependency | No dependency exists today; GET-only, loopback-only, no bodies needs about 200 lines | The parser is ours to keep correct; it is attacked in this record |
| `respond` is a pure function of verb, target, and headers | Decide inside the socket loop | Every refusal can be reasoned about and tested without timing | Socket handling is only reading, writing, and limits |
| A thread per connection | A single-threaded accept loop | Browsers open idle speculative connections; one silent socket would stall everything for the read timeout | A connection limit is needed, and an eviction rule when it is reached |
| Fresh `ControlPlane` and `ChangeIndex` per answer | Build once at startup | `ControlPlane` memoises the workflow and skills; a long-lived process would serve a stale lifecycle | A few YAML reads per uncached answer |
| 2 s reuse of each API answer under one mutex | No cache; per-key locks | Several tabs must not each start git subprocesses | A record edit shows up after at most 2 s plus the 5 s poll |
| The page's files are served to any site's navigation; data routes are not | Refuse every cross-site request | A link to the page, or an automated browser, is a cross-site navigation and must open | The page shell is public to the local browser; it contains nothing about the repository |
| Slug in the query string | Slug in the path | Slugs may contain "/" | `/api/change?slug=team%2Falpha` |
| One page, hash routes, no framework | A build step; server-rendered pages | No dependency, no toolchain, and the CSP can forbid everything but two files | About 400 lines of script |
| Redraw on change only, restoring focus by key | Patch the DOM in place | Simple and enough: focus, scroll, and the selected gate survive a poll | A whole view is rebuilt when its data changes |
| Each state has a CSS shape and a word | Icons from a font or SVG sprite; colour badges | Nothing to load, and colour is never the only signal | Ten shapes defined in the stylesheet |
| Palette and type from the subject: sand, graphite, and colour only for the state of the metal; system fonts in a condensed display stack | A web font; a generic dashboard look | No remote fonts under the CSP; the lifecycle is a line metal runs along, and "gate" is a foundry word | The gate strip is the one distinctive element; the rest is plain |
| The Pause control keeps its label | Swap the label to "Resume" | A toggle that changes both label and pressed state reads ambiguously to a screen reader | State is `aria-pressed` and the text beside it |
