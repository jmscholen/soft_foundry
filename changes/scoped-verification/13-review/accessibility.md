# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. Examined the output a person reads or operates at `8575131`:

- CLI: `soft-foundry change size` prints `phase:`, `size:`, `scope:`, `base:`, and `reason:` on their own lines (`cli.rb`). Gate lines use the words pass, fail, skip, and warn, with `scope:` and `reason:` continuations indented (`gate.rb` `scoped_stale_detail`). Errors from sizing and declarations name the next step (declare a path that exists, pass `--since`, restore the policy file). No new prompt. `test_size_output_is_words_prefixed_lines_with_no_prompt_and_plain_ascii` covers `NO_COLOR=1` and ASCII-only size output. Evaluation EVAL-011 recorded the same on the transcripts.
- Browser view: `app.js` `changeView` renders scope as the text `Scope: ` plus the glob list, in the same `.meta` line as status, risk, and type. Staleness is the word `Stale` on the board flag and the sentence "stale evidence: code changed after the commit the evidence describes." State is not color alone (WCAG 2.2 1.4.1). The scope span adds no control; the existing keyboard path (links, `:focus-visible` in `app.css`) is unchanged (2.1.1, 2.4.7, 4.1.2). The meta line uses the existing `--steel` on `--ground` tokens, the same color as the status text beside it (1.4.3 as applied to that line).
- Documents: the README sizing and branch paragraphs and the review files use heading hierarchy. No new image.

This phase did not drive a browser, a screen reader, or a keyboard-only pass. The conclusion is from `app.js`, `app.css`, the CLI, the size-output test, and evaluation's accessibility observations. EVAL-012 did not drive a browser either.

## Findings

No findings.

## Conformance

Conforms. CLI outcomes are words, one fact per line, with a stable prefix, and errors name a next step (command-line rules in `.ai/rules/accessibility.md`; WCAG 2.2 1.4.1, 3.3.1, and 3.3.3 as applied to that output). Scope and staleness in the browser view are text, not color alone (1.4.1), and the new scope span adds no control beyond the existing keyboard path (2.1.1, 4.1.2).
