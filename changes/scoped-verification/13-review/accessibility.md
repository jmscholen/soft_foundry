# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. Examined the new and changed output a person reads or operates:

- `soft-foundry change size` (`cli.rb` `change_size`): lines prefixed `phase:`, `size:`, `scope:`, `base:`, `reason:`. No prompt. Failures from `Sizing` and `TargetError` name the cause and the next step (`--since`, the phase list, restore the policy file).
- `soft-foundry gate` (`print_result`): the phase line uses the words `PASS`, `FAIL`, and `SKIP`. Each check uses the word `pass`, `fail`, `warn`, or `skip`. A glyph may sit beside the word. Continuation lines of a stale result keep `scope:` and `reason:` on their own lines. No ANSI color is emitted on this path. Stripping the check glyphs leaves the words, which is what AC-019 and the evaluation transcript recorded under `NO_COLOR`.
- `soft-foundry change status`: `scope:` is its own line when a scope is declared. Advisories use `advisory:` and `! warn`.
- Browser change view (`lib/soft_foundry/ui/assets/app.js`): the scope is a text node `Scope: ` plus the glob list via `textContent`. Gate state is the words in `STATES` (`Pass`, `Fail`, `Stale`, and the rest), and each state mark is paired with that word. Existing skip link, `:focus-visible` outline, and heading hierarchy are unchanged. The new span adds no control.
- Contrast of the meta line that now includes scope, from `app.css`: `--steel` `#55606c` on `--ground` `#e9ecef` is about 5.4:1, above the 4.5:1 body-text ratio (1.4.3). Dark theme uses a lighter steel on a near-black ground. This phase did not open the page in a browser; the evaluation phase recorded the same limit. The conclusion is from the script and the stylesheet.

Requirements REQ-021 and REQ-022, and evaluation section "Accessibility observations".

## Findings

None.

## Conformance

Conforms. CLI outcomes are words, one fact per line, with a stable prefix, and errors name a next step (command-line rules in `.ai/rules/accessibility.md`; WCAG 2.2 1.4.1, 3.3.1, and 3.3.3 as applied to that output). Scope and staleness in the browser view are text, not color alone (1.4.1), the meta text meets 1.4.3, and the new scope span adds no control beyond the existing keyboard path (2.1.1, 4.1.2).
