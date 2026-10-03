# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| Who may read | A request carrying the token | Everything else that can reach the port | Token in a header, constant-time comparison, never accepted elsewhere (MIT-002) |
| Which directories are read | Repositories the server registered itself | Any path or id a request supplies | Issued ids only; registration requires `.ai/workflow.yml`; a change is checked against its own repository's listing (MIT-001) |
| The token | The terminal, the tab's session storage, the request header | The address bar, history, Referer, other origins | Fragment in the link, removed from the address on arrival; `Referrer-Policy: no-referrer`; no CORS; preflight refused (MIT-003) |
| Other repositories' content | The page's own script and markup | Names and records from repositories found through sessions | Text nodes only; CSP unchanged (MIT-004) |
