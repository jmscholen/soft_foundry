# Security Review

## Scope reviewed
Whether the new views change the server's surface or how record text is rendered.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | server | No route, header, or refusal changed; `ui_server_test.rb` passes unchanged. | No new surface |
| REV-010 | info | `app.js` | The new code builds DOM only through `el`; the static test that forbids markup-parsing APIs still passes. Markup in a decider's name rendered as text, and markup in a time kept the event off the timeline (EVAL-005). | XSS |
| REV-011 | info | spend | Ledger entries name who recorded them (`recorded_by`) in the data; the page does not show that field. | Data minimisation |

## Conformance
Conforms. The accepted risk from ui-server (no authentication) is unchanged.
