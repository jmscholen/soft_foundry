# Accessibility Review

Standard: `.ai/rules/accessibility.md` (command-line and log output rules). No user interface is added or changed, so no WCAG 2.2 interface criterion is in scope. `surfaces.accessibility` is true because a person reads the new CLI lines.

## Scope reviewed

The new lines from `PhaseRunner#default_shell`, printed by `CLI#phase`:

- `shell: codex (implementation ran on anthropic; the review skill prefers a different provider)` on standard output
- `! warn shell: …` on standard error (the line starts with `!`, and that is what selects stderr)

Also the existing gate line for `findings explained`, which already uses the words the gate uses for every check. No prompt, color, or glyph was added. EVAL-005 deleted non-ASCII bytes from the `shell:` line and the meaning survived; the lines this review probed are ASCII.

The four shapes the probe printed were read as text: the plain `shell:` line, the warning that names a missing provider and the provider the choice differs from, the warning that no installed shell is on another provider, and the warning that a provider is not recorded so the first installed shell is used.

## Findings

None.

## Conformance

Conforms. Each new line carries a status word (`shell:` or `warn`), one fact per line, with no color and no interactive prompt. Meaning does not depend on a glyph or on terminal width. The `!` on the warning accompanies the word `warn`; it is not the only signal.

The specification phase was skipped, so the go-live advisory that no accessibility requirement was recorded still applies. That advisory is about the skip. It is not a defect in these lines, and this file does not declare conformance N/A.
