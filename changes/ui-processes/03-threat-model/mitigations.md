# Mitigations

| ID | Threats | Mitigation | Where enforced | Verified by |
| --- | --- | --- | --- | --- |
| MIT-001 | THREAT-001 | A process is listed only when soft-foundry is the executable (or the script ruby runs). Command, phase, change, shell, and port are each matched against a fixed list or a strict pattern; arguments after `--` are dropped; a child is reported by name and pid only. The raw line never leaves. | `Processes#arguments`, `#describe`, `#phase_of`, `#change_of`, `#shell_of`, `#session` | `test_nothing_from_a_command_line_is_repeated_beyond_validated_fields`, `test_lists_only_soft_foundry_processes_with_what_they_are_doing`; ATTACK-001, ATTACK-004 |
| MIT-002 | THREAT-002 | `ps` and `lsof` run through `Open3` with argument arrays; the route reads no parameter. | `Processes#run_ps`, `#cwd_of`; `UI::Server#respond` | `test_api_returns_running_processes`; ATTACK-002 |
| MIT-003 | THREAT-003 | The route is a data route: Host check, cross-site refusal, no CORS, GET and HEAD only. | `UI::Server#respond` | `test_api_returns_running_processes`; ATTACK-002 |
| MIT-004 | THREAT-004 | Accepted. The list says what the process table says. The page states what it lists and what it cannot see, and nothing can be controlled through it. | Recorded here; the note under the table | n/a |
