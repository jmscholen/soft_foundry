EVAL-006 (REQ-GDH-004): README.md as of commit 2af76ba9b26be41af5bcafa12ee56eda635f6c77, before the documentation phase runs.
Each item intake REQ-GDH-004 says the README must say, searched for by the words a reader would look for; 'none' means the README does not mention it yet.

'Grep': 0 line(s)
'Glob': 0 line(s)
'guard --after': 0 line(s)
'PostToolUse': 0 line(s)
'post-call': 0 line(s)
'interrupted': 0 line(s)
'fail closed\|cannot decide\|undecidable': 0 line(s)
'segment': 0 line(s)
'\.soft-foundry/': 5 line(s)
    46:The accessible model inventory is written to `.soft-foundry/runtime.yml`, which is machine-local and must remain gitignored. Credentials are never written to
    131:The mode is declared in `.ai/policies/enforcement.yml`: `block` by default since 0.21.0 (refuse the call: the hook exits 2 with the reason, and the refusal 
    439:The override lives in `.soft-foundry/budget.yml`, next to the runtime inventory and equally gitignored.
    470:**What the ledger keeps, and where.** `~/.soft-foundry/sessions.jsonl` (or `SOFT_FOUNDRY_SESSIONS`), one line per session, readable only by you: the agent, 
    487:- `.soft-foundry/` — local provider/model runtime state; never committed.
'existing repository\|rerun\|re-run': 5 line(s)
    85:**A phase is sealed, not committed by hand.** `soft-foundry phase seal <phase>` runs the gate and, when every check passes, commits exactly the phase directo
    89:The specification is locked once recorded: on the gated track from the commit that recorded the completed specify phase (the newest commit touching its hando
    189:The verification gate's `red evidence` check verifies the shape of that claim: the commit exists, precedes the verified commit, holds the test file, and `AP
    328:### Scoped verification: re-run only what a change can affect
    330:By default any code change makes every record's commit-bound evidence stale and every verify re-run everything. A change can narrow that:
'allowedTools\|permission-mode': 1 line(s)
    227:soft-foundry phase run plan --panel claude,grok --shell-arg claude=--permission-mode=acceptEdits --shell-arg grok=--always-approve

== the guard section, README.md lines 117-137, as it stands (the text the documentation phase must bring up to date):
### Runtime enforcement: the guard hook

Every skill's `permissions.yml` declares what it may read and write, and `check` lints those declarations. `soft-foundry guard` enforces them while a coding shell is running: it is a Claude Code PreToolUse hook that reads each tool call, resolves the active change from the branch and the active skill from the change's status and `current_phase` (the track's stage skill while exploring), expands the skill's sets through the path groups, and decides.

```bash
soft-foundry hooks install --claude            # writes the hook into .claude/settings.json (shared)
soft-foundry hooks install --claude --local    # or .claude/settings.local.json (this machine only)
soft-foundry hooks install --codex             # writes the same hook into .codex/hooks.json; then trust it with /hooks inside Codex
soft-foundry hooks uninstall --claude          # removes only Soft Foundry's entry (likewise --codex)
soft-foundry doctor                            # reports which hosts have the hook and the mode in effect
```

The guard itself is host-neutral: it reads a JSON tool call on stdin and exits 2 to refuse. Claude Code and Codex share the hook file shape and the `PreToolUse` event. Codex names its shell tool `Bash` too, may send `command` as an array, and reports file edits as `apply_patch` (or under the `Edit`/`Write` aliases) with the patch text in `command`; the guard reads every path the patch adds, updates, deletes, or moves to and checks each against the write sets. Codex runs a project hook only after a person reviews and trusts it with `/hooks`. Grok (checked against 1.0.30) runs the Claude Code entry from `.claude/settings.json`, but only in a folder it trusts (`/hooks-trust` or `--trust`), and sends its own tool names: `write` and `search_replace` are checked as writes, `read_file` (path in `target_file`) as a read, and `run_terminal_command` as a shell command. `phase run --shell grok` reminds you of the trust step.

The mode is declared in `.ai/policies/enforcement.yml`: `block` by default since 0.21.0 (refuse the call: the hook exits 2 with the reason, and the refusal is logged to the machine-local `.soft-foundry/guard.log`); `warn` (report the violation, let the call through, log it); `off`. A maintainer's machine can override it in `.soft-foundry/enforcement.yml` or with `SOFT_FOUNDRY_GUARD=warn|block|off`, which wins over both. Neither can be reached from inside a guarded session: the guard treats its own configuration (`.ai/policies/enforcement.yml`, `.soft-foundry/enforcement.yml`, and the hook entries in `.claude/settings.json`, `.claude/settings.local.json`, and `.codex/hooks.json`) as denied to every skill, for the write tools and for any shell command that names one, and a command's environment ends with the command. Outside a change branch, or once a change is closed, nothing is guarded. `doctor` and `hooks install` print the mode in effect and where it comes from.

What is checked: Edit, Write, MultiEdit, NotebookEdit (and Grok's `write` and `search_replace`) against the write and deny_write sets; Read (`read_file`) against deny_read only; Bash (`run_terminal_command`) against the deny sets only, because the guard cannot know what a command writes, so it refuses a command that names a denied path and passes everything else. A restriction the guard cannot see is still policy the agent must honor, as `AGENTS.md` says. Every refusal or warning names the tool, the path, the skill, and the mode:

```
✗ fail guard: Edit .ai/rules/ruby.md is in implementation's deny_write set; the implementation skill's permissions.yml does not allow it (mode: block, .ai/policies/enforcement.yml)
```

== the harness-evals section mentions of --live (lines):
373:soft-foundry eval --live --shell claude             # also the live cases, each in a fresh session through `phase run`
376:A **gate case** plants a defective change record in a scratch git repository carrying this repository's control plane (a review finding with no failure named, evidence left stale by a code change,
380:- skip eval review-finds-planted-defect: live case; run `soft-foundry eval --live --shell claude|codex|grok --case review-finds-planted-defect`
