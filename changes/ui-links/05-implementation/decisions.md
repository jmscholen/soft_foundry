# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Four link makers, each stamping `data-ref` | Ad hoc anchors | One place per kind of reference decides the address and what the popup needs | A reference made any other way has no popup; a static check counts them |
| Popups from data already on the page | Fetch on hover | No request, no delay, nothing new to secure | A gate in another change says less (no state) until that change is opened |
| Free text links only `NN-name` directory names | Also phase ids | "review" and "verify" are ordinary words in advisories | A phase named only by id in prose is not linked |
| The path is shown, not opened | Serve record files | The server serves no file contents, by design | The popup says where to look |
| A commit is a focusable span, not a link | A link to a code host | No host is known and the server reads git only locally | Its popup gives the `git show` command |
| Column headers link to the Workflow | No link | A column header is a reference to a phase | 32 more tab stops on a board with two tables |
| One tooltip element reused | One per reference | A single `role="tooltip"` element is easy to describe by id | Only one popup at a time, which is right |
