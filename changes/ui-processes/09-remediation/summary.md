# Remediation Summary

Trigger: the maintainer, after the first delivery: "this does not seem to be capturing other session running in other terminals". Five coding-shell sessions were open in four Soft Foundry repositories at the time (four claude, one grok); the list showed one process, a `ui` server.

Cause: recognition was by how a process was started (`soft-foundry ...`). An interactive session is started as `claude`, `codex`, or `grok`, so none qualified. The first record even named this as a non-goal; the request had been misread.

| Finding | Fix | Test (RED `79e48c2`, GREEN `dd18466`) |
| --- | --- | --- |
| Sessions opened by hand are not listed | `Processes#sessions` lists every claude, codex, or grok process whose working directory is inside a repository with `.ai/workflow.yml`, with terminal, branch, change, and the change's recorded phase and status; shown in `ps`, `/api/processes`, the Running view, the board, and each change | `test_lists_coding_shell_sessions_open_in_soft_foundry_repositories`, `test_a_session_reports_nothing_unvalidated_from_another_repository`, and the `ps` output tests |

After the fix, with the same five real sessions open, `soft-foundry ps` listed all five with their terminals and branches, and the Running view showed them. Verification, evaluation, and attack were produced again at `dd18466`; an attack case for hand-started sessions was added (ATTACK-005). The maintainer's own sessions are counted in the committed transcripts and not named, since their repositories and branches are not this repository's to publish.
