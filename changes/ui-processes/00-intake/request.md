# Change Intake

## User intent
"next phase is that it picks up any soft foundry process running or said better, it will display any soft foundry process running", then, while it was being built: "multiple sessions". The page should show every Soft Foundry process that is running, several at once, whichever session or repository started it.

## Desired outcome
- REQ-PS-001: `Processes` lists every process started as `soft-foundry ...` by the current user on this machine, in any repository: its command, the phase and change it concerns, the port for a `ui` server, the coding-shell session a phase runner launched (name and pid), its repository, whether that is the repository being viewed, whether it is the process asking, and when it started.
- REQ-PS-002: only named, validated fields are reported. A command line is never repeated: not arguments after `--`, not a session's prompt, not a value that fails validation. A process that only mentions soft-foundry is not listed.
- REQ-PS-003: when a command does not name its change, the change is the one its repository's checked-out branch belongs to.
- REQ-PS-004: phase runs this repository's open records say were started and never finished are reported, each marked live (with the pid) or not. A run with no live process is an interrupted session.
- REQ-PS-005: `soft-foundry ps [--json]` prints one line per process, leaves itself out, warns on interrupted runs, exits 0, and exits 1 with a reason if the process list cannot be read.
- REQ-PS-006: the server answers `/api/processes` under the same refusals as the other data routes, and listing never signals or changes a process.
- REQ-PS-007: the page has a Running view listing every process, with changes in this repository linked and interrupted runs listed; the board flags changes with something running or interrupted and says how many processes are running; a change says what is running on it now and marks the gate. All of it follows processes starting and stopping.
- REQ-PS-009: every coding shell (claude, codex, grok) a person has open in a repository that has a Soft Foundry control plane is listed as a session, in any terminal and any repository: the shell, its terminal, its repository, the checked-out branch, the change that branch belongs to, and the phase and status that change's record gives. A phase runner's own session and a shell's child processes are not listed twice; a shell outside any Soft Foundry repository is not listed. Added after the maintainer reported that the first version "does not seem to be capturing other session running in other terminals".
- REQ-PS-008 (accessibility, WCAG 2.2 AA): the new view keeps the page's floor: a table with caption and scoped headers (1.3.1), words rather than colour for running and interrupted (1.4.1), keyboard reachable links (2.1.1), no sideways page scroll at narrow widths (1.4.10); the command's output is line-oriented words with no colour.

## Constraints
- No new dependency: `ps` everywhere, `/proc/<pid>/cwd` where it exists and `lsof` otherwise, run with argument arrays and never through a shell.
- Read-only. No signal, no write, no control of a process from the page or the command.
- `.ai/rules/security.md`: a process's command line is input anyone on the machine may have written.

## Non-goals
- Stopping, restarting, or attaching to a session.
- Saying what a session is doing at this moment. A session's phase is what its change's record says, which is where the work stands, not a reading of the session.
- Sessions in tools other than claude, codex, and grok (an editor's assistant, a desktop app working outside a Soft Foundry repository).
- Other users' processes, other machines, history of past runs.
- Windows.

## Task classification
feature

## Initial risk
low. Reads the process table the user can already read, reports a few validated fields, and adds one read-only route behind the existing refusals.
