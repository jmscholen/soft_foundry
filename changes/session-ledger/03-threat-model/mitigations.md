# Mitigations

| ID | Threats | Mitigation | Where enforced | Verified by |
| --- | --- | --- | --- | --- |
| MIT-001 | THREAT-001 | Session IDs must match a plain-identifier pattern or the payload is not recorded; folders are shell-quoted with `Shellwords.escape` when the command is built | Session ledger | AC-010, ATTACK-001 |
| MIT-002 | THREAT-002 | Prompts pass through the content scan's secret patterns and are masked before writing; cut to 140 characters | Session ledger | AC-004, ATTACK-003 |
| MIT-003 | THREAT-003, THREAT-007 | Control characters (C0, C1, DEL) are removed from every recorded text field; the UI renders through text nodes only | Session ledger; `app.js` | ATTACK-002, ATTACK-007 |
| MIT-004 | THREAT-004 | Directory 0700, file 0600; a symlink at the ledger path is refused and nothing is written | Session ledger | AC-004, ATTACK-004 |
| MIT-005 | THREAT-005 | At most 1 MB of stdin is read; any error exits 0 silently; lines that do not parse are kept, not dropped; hook entries carry a 10-second timeout | Session ledger; installer | AC-005, AC-014, ATTACK-005 |
| MIT-006 | THREAT-006 | Installer edits only entries carrying its marker, writes through `SafeWrite`, refuses symlinks and non-object JSON without writing | Hooks installer | AC-011, ATTACK-004 |
| MIT-007 | THREAT-008 | Grok's four tool names mapped to the existing write, read, and shell decisions; an unknown tool name stays "not guarded" (residual: a future Grok tool name) | Guard | AC-001, ATTACK-006 |
| MIT-008 | THREAT-009 | Exclusive `flock` held from read to rewrite | Session ledger | AC-006 |
