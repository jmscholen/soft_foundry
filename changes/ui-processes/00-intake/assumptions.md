# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase; review and attack are not independent, and the advisory says so for review.
- "Any soft foundry process" is read as machine-wide for the current user, across repositories, because the maintainer runs phase sessions in more than one project at once (one was running in another project during the earlier work) and then said "multiple sessions". The repository being viewed is distinguished, not filtered to.
- Correction after first delivery: "session" in the request meant the coding shells the maintainer has open in terminals, not only processes started as `soft-foundry`. The first version listed one process where five sessions were open in four repositories. A session is now recognised by what it is (a claude, codex, or grok process) and where it is (inside a repository with `.ai/workflow.yml`); see `09-remediation/summary.md`.
- A process is recognised by how it was started: the `soft-foundry` executable, or ruby running it. That finds processes started before this change existed, which a registry written by new code would not.
- Another repository's path is shown (home shortened to `~`). The earlier views avoided absolute paths of the viewed repository; here the path is the only way to say which session is which, and the viewer can read it from `ps` already.
- Stacked on `ui-explainer-timeline`.

## Ambiguities resolved
- `ps` or a run registry: `ps`. A registry needs every command to write and clean up a file and misses crashes; the handoff's `executed_by` already is the registry for phase runs, and is used for exactly the crash case (REQ-PS-004).
- Whether the list includes the process asking: the server marks itself and the page labels it; `soft-foundry ps` leaves itself out.
- What to show for an unknown shell name: nothing of the name; the runner's default is reported.

## Ambiguities that block safe progress
None.
