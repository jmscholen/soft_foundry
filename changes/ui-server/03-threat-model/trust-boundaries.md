# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| The machine | The server process on 127.0.0.1 | Any other host on the network | Loopback bind; no `--host` flag (MIT-007) |
| The page's origin | The page served from `127.0.0.1:PORT` | Every other origin in the viewer's browser | Host header check, `Sec-Fetch-Site` check on data routes, no CORS headers, JSON content type with `nosniff`, `frame-ancestors 'none'` (MIT-001, MIT-002) |
| The route table | Six fixed routes and three packaged files | The repository's files and the rest of the disk | Exact-match routing; slug accepted only from the repository's own listing (MIT-003) |
| Record text | The page's own script and markup | Strings from `changes/` and `.ai/` | Text nodes only; CSP without inline or remote script (MIT-004) |
| The viewer's user account | The person who ran the command | Other local users and processes | None. Accepted: read-only, and the files are on the same disk (THREAT-008) |
