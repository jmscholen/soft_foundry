# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase. The review and the attack are therefore not independent; the advisory says so for review on every gate run.
- The requirements, the server design, and its security checks were fixed in the plan the maintainer approved before any code. Intake and the threat model were written into this record after the implementation, from that plan; their content predates the code, their files do not. The handoff times say when the files were written.
- A hand-written server is preferred to adding `webrick`: it would be the gem's first runtime dependency (`.ai/rules/dependencies.md`), and a GET-only loopback server needs a small fraction of what it parses.
- The viewer is the person who ran the command, on their own machine, in a current browser (one that sends `Sec-Fetch-Site`).
- Depends on change `ui-snapshot` (the data layer), on whose branch this is stacked.

## Ambiguities resolved
- Whether a link to the page from elsewhere should open: yes. The first design refused every cross-site request, which also refused the page itself when opened from a link or by browser automation. The page's three files say nothing about the repository, so they are served regardless; the three data routes are refused. Found in the first browser run.
- Whether closed records are gated: not on the board (as `ci`); yes when one is opened, with a note that stale gates are expected there.
- Whether the Pause control changes its label: no. It is a toggle with `aria-pressed`; the status text beside it says "Paused".

## Ambiguities that block safe progress
None.
