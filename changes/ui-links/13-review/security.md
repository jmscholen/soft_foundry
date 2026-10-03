# Security Review

## Scope reviewed
What the popups show and how they are built.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | `showTip` | The popup is filled with `textContent` through the same `el`/`add` helpers; record text (titles, rationales, check details) stays text. The static test that forbids markup-parsing APIs still passes. | XSS |
| REV-010 | info | `data-*` attributes | Slugs, phases, and repository ids from the data are set as attribute values with `setAttribute` and read back only to look up data; no attribute value becomes a URL without `encodeURIComponent`. | Injection |
| REV-011 | info | paths in popups | A popup for a reference in another repository shows that repository's directory, which the list of repositories already shows. Nothing new is disclosed. | Data exposure |

## Conformance
Conforms.
