# Learning

## What this change taught us
- **A unit test that encodes an external CLI's argument order proves nothing about that CLI.** REM-001: the runner built `grok -p -s <id> … <prompt>`, and the unit test asserted exactly that order, so it passed. Only the first live `phase run review --shell grok` showed that Grok's `-p` takes the prompt as its value. The same fault had existed since 0.15.0 whenever extra arguments followed `-p`. EVAL-008 now runs the runner's own launch live.
- **Hook capability claims age.** The repository (code comment, README, and a maintainer-facing note) said Grok had no hooks; Grok 1.0.30 has a full hook system and already ran the Soft Foundry guard from `.claude/settings.json`, passing every call because the guard did not know its tool names. Re-checking the installed CLI found a live guard gap.
- **Cross-provider fresh-context review earns its keep.** The Grok review, run through `phase run`, found REV-SEC-001 (the session ID is trusted on the way out of the ledger), which the implementing session's own threat model had framed only at the recording boundary.
- **Evidence scripts leak the very secrets they test for.** The first attack transcript printed the fake keys it checked for and failed the `content clean` gate; the script was fixed to print key names and every case was rerun, as the existing `sanitize-transcripts-before-they-become-evidence` instinct says.
- **Timestamps are evidence too.** The first handoffs carried guessed times, some later than the actual clock; they were reset from git commit times and file modification times before anything was committed past them.

## Reviewer/evaluator/attack findings worth generalizing
- REV-SEC-001: validate data where it is used to build a command, not only where it is first accepted. Any value that crosses into a printed shell command needs quoting or re-validation at that point.
- REM-001: launch arguments for a third-party CLI need one live run before review, not just a unit test of the array.
- EVAL-OBS-001: a command a person must copy belongs on its own labelled line.

## Proposed deterministic checks
- In `phase run --dry-run` (or `doctor`), run each installed shell's `--help` and check that the runner's flags exist for that version; warn when they do not. Motivated by REM-001.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
