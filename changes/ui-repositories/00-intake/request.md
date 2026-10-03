# Change Intake

## User intent
"I dont understand the flow of the UI.. you have the changes link, and it only shows what looks like soft foundry repos affected, but under the running you show three other repos". The page had two scopes and said neither: Changes showed the records of the one repository the server was started in, Running showed sessions across the machine, the page never named its repository, and a session in another repository led nowhere. Offered three ways to make it coherent, the maintainer chose "All repositories": one page for the machine.

## Desired outcome
- REQ-REPO-001: the home page is Repositories: the repository the server was started in, any named with `--repo`, and any in which a coding-shell session or a soft-foundry command is running. Each shows its name, where it is, its sessions (shell, terminal, branch, change, recorded phase), commands running, its open changes with recorded status and phase, and how many are closed.
- REQ-REPO-002: each repository has its own pages: its Changes board, each change's gates, and its Workflow, at an address that names the repository. Every such page says which repository it is, with a way back to Repositories and between its Changes and Workflow.
- REQ-REPO-003: Running links every session and command to its repository, and to its change in that repository when it has one. A change says what is running on it in its own repository, not in the server's.
- REQ-REPO-004: a repository found through a session stays known for as long as the server runs. One that appears later is picked up without a restart.
- REQ-REPO-005: a request names a repository only by an id the server issued. A path, an unknown id, or an empty value is "no such repository". With no repository named, the one the server was started in is meant. A change is looked up only in its own repository.
- REQ-REPO-006: data is answered only to a request carrying the server's token in a header. The token is random per run, is in the link the command prints (after the `#`, where a browser keeps it to itself), is never accepted in the address or a cookie, and is compared in constant time. The page takes it from the link, removes it from the address bar, keeps it for the tab, and says what to do when it has none. The page's own files need no token and contain nothing about any repository.
- REQ-REPO-007: no absolute path leaves except where a person needs it to tell repositories apart: the list of repositories and each running entry's repository, with the home directory shortened. Boards, changes, and workflows carry none.
- REQ-REPO-008 (accessibility, WCAG 2.2 AA): the repository bar is a labelled navigation landmark with the current page marked (1.3.1, 2.4.8); every page has a title naming the repository (2.4.2); headings give each card structure (1.3.1, 2.4.6); nothing depends on colour (1.4.1); no sideways page scroll at narrow widths (1.4.10); the token refusal is explained in text with what to do (3.3.1, 3.3.3).

## Constraints
- Read-only still. No new dependency (`securerandom`, `digest`, `openssl` are standard library).
- The server now reads records from repositories it was not started in. Those are attacker-writable input as before, and rendered as text as before.
- Addresses from the earlier changes (`#/change/<slug>`, `#/workflow`) keep working and mean the repository the server was started in.

## Non-goals
- Finding repositories by scanning the disk. A repository is known because the server was started there, it was named, or something is running in it.
- Remembering repositories between runs.
- A fixed token for bookmarks. The link changes each run.
- Changing `soft-foundry ps`, which already lists across repositories in a terminal.

## Task classification
feature

## Initial risk
medium. The server's reach grows from one repository to several, addressed by request, and an authentication mechanism is introduced. Contained by issued ids, the token, and the existing refusals; threat-modelled and attacked in this record.
