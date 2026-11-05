# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is false. Examined the diff and every place a person reads the version: `lib/soft_foundry/version.rb`; `lib/soft_foundry/cli.rb` (`version`, `--version`, `-v`, and the help header `Soft Foundry #{SoftFoundry::VERSION}`); the unknown-command path, which prints that help and exits 1; `lib/soft_foundry/updater.rb` (unchanged lines); `README.md` (the Updating section does not hard-code a version); `docs/user/README.md` (unchanged). No HTML, native view, or new document. EVAL-001's sweep shows `soft-foundry version` printing `0.23.0` and exiting 0.

## Findings

None.

The only difference a person can read is the token `0.23.0` on lines that already existed. Those lines stay plain ASCII, one fact per line, with no color and no glyph. An unknown command still prints the usage text, including the version, and exits 1. That exit status predates this change (`route-sweep.txt` marks `help` unexpected against the sweep's own expectation).

## Conformance

Conforms to the command-line rules in `.ai/rules/accessibility.md` for the lines this change alters. WCAG 2.2 user-interface criteria have no control to apply to: the change renders no HTML, native view, or document UI. `surfaces.accessibility` is false, and the repository profile lists no user-facing framework.
