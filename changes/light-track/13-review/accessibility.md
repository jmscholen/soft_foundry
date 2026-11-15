# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility` is true. Examined:
- `soft-foundry change status` on this record and in EVAL-008, with `NO_COLOR=1`, no terminal, and every non-ASCII character removed.
- The new and changed messages: the unknown-track refusal, `track permitted`, the outside-change refusal, the cap refusal and the cap check, and the sizing reason.
- `docs/user/light-track.md` (new), the rows added to `docs/user/README.md`, and the tracks section of `README.md`: heading order, tables, code blocks, link text.
- The `--track` line of `soft-foundry help`.

There is no browser UI in this change. `soft-foundry ui` was not opened with a light record (evaluation lists it as not swept).

## Assessment
- Outcome in words: each stepped-over phase carries its reason as text ("optional on the light track", "stepped over by default at low risk", "optional", "waived: named in skipped_phases"). A glyph only accompanies a word. Rule: every outcome is conveyed by a word.
- Colour and symbols: no escape sequence with `NO_COLOR=1` and no terminal; lines keep their meaning with non-ASCII removed (EVAL-008). Rule: meaning survives stripping escapes and non-ASCII.
- Line-oriented: one phase per line, beginning with its directory name; trailing spaces are now removed.
- No prompt was added.
- `docs/user/light-track.md`: one level-one heading followed by level-two headings in order; both tables hold tabular data with a header row; code blocks name their language; the index link text is the page title. Rule: real heading hierarchy, tables with a header row (WCAG 1.3.1, 2.4.6).

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | major (graded in functional.md) | `lib/soft_foundry/sizing.rb` | The accessibility part: when an ignored path prevents the smaller size, the reason printed is "no scope declared", which is not what went wrong. | See functional.md | CLI rule: error messages name what went wrong and what to do next |
| REV-009 | minor | `README.md`, "Lifecycle tracks: gated, iterative or light" | A blank line separates the `light` bullet from the `gated` and `iterative` bullets, so the three tracks are announced as a list of two and a list of one. The `light` command block also sits directly above the iterative one with nothing between them to say which track each belongs to. | | WCAG 1.3.1 Info and Relationships |
| REV-004 | minor (graded in functional.md) | `soft-foundry help` | The help does not say what the light track is, so a person choosing a track from the terminal has to open another document. | | REQ-009; WCAG 3.3.2 Labels or Instructions |

## Conformance
Conforms with advisories: REV-009, and the reason text in REV-002.
