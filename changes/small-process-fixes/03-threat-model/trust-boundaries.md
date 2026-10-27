# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| Command-line arguments | `soft-foundry` process | Person or CI script supplying `--type`, `--risk`, `--track`, slug | Allowed-value lists checked before any write; slug must name a known change or a valid new slug; refusal says what was wrong and what to do |
| Agent handoff to runner | Runner process and the phase directory it owns | Fresh-context agent session that wrote the handoff, possibly steered by untrusted content | Runner parses with the safe YAML loader, changes only `status` and appends to `notes` of that one handoff, under the record lock; gate rules unchanged |
| Recorded files to summary and gate | Summary and gate readers | Free text in metadata, handoffs, findings, `tests.yml` written by agents and people | Read-only; control and bidirectional characters escaped when echoed; size-bounded reads; unreadable file shown as `unreadable` |
| Repository profile globs to parity check | Gate check | `access_control` globs from discovery and changed paths from Git | Glob matching only, no shell; unreadable glob fails the check; check is structural and does not prove the claim |
| Evidence text to content scan | `check` scanner | Quoted payloads in evidence and guidance | Scanner unchanged; guidance requires visible escapes or script-built payloads |
