# Security Review

## Scope reviewed

The same commit and diff, against `.ai/rules/security.md`, `.ai/rules/access-control-parity.md`, the threat model (THREAT-001 through THREAT-010), and the attack results at `821f1e8`. This repository's `.ai/repository.yml` declares no `access_control` globs. `06-verification/tests.yml` states `protection: not_applicable` on CHECK-001, CHECK-002, and CHECK-003, with no note. The rule requires a note for `disabled`. The gate skips `protection stated` when the profile has no `access_control`, which matches this record. No check claims `in_force`. No test helper in this change disables a protection.

Payloads in the attack evidence are cited by behavior. This file does not paste raw format or bidi characters.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-004 | minor | `lib/soft_foundry/gate.rb` `access_control_problems` | A glob is rejected for `Declarations.syntax_problems` or an unequal count of `[` and `]` or `{` and `}`. A format character (zero-width, bidi) is neither. The glob then matches no path, and `protection_check` skips. Attack ATTACK-007 showed the lint returning no problem for such a glob. `soft-foundry check` scans `.ai/**` and would still report the invisible character in `repository.yml` when check runs. The parity check itself does not. | Profile `access_control` lists a glob that differs from a real protected path only by a format character such as U+200B. `gate verify` skips `protection stated`. A verification record with no `protection` field passes that check. | REQ-013; THREAT-007; `.ai/rules/access-control-parity.md` |
| REV-005 | minor | `lib/soft_foundry/change_summary.rb` `handoff` / `read` | `File.file?` and `read_text` follow a symlink. A `handoff.yml` or `metadata.yml` that points at another YAML file contributes that file's `status`, `blocking`, and `findings` to the summary. `Display.safe` still strips control and format characters from the echoed text. Attack ATTACK-008. Planting the symlink takes write access to the record, which is already enough to read the target on the same machine. The new effect is that `change summary` prints the target's fields into the terminal or the CI log. | `changes/<slug>/<phase>/handoff.yml` is a symlink to another YAML file whose `blocking` list holds a value that should not be in the log. `change summary` prints that value on a `blocking:` line. | THREAT-001; `.ai/rules/security.md` (change records are attacker-controlled inputs) |
| REV-007 | minor | `test/display_test.rb` lines 10 and 20 | The escaper test embeds the raw characters U+202E, U+200B, and U+2066 in the source. The guidance this change added tells agents to build those characters with a source escape such as `\u{200B}`. The assertions can be written that way and still pass the character to `Display.safe` at runtime. | Open `test/display_test.rb` in an editor that honors U+202E. The assertion on that line is reordered on screen, so a reader cannot see the sequence the test claims to check. | `.ai/rules/security.md` (no invisible Unicode in files that are read as source); the review and verification skill guidance |

## Conformance

Conforms with the advisories above.

No new trust boundary, credential, network client, or privilege. `mark_blocked!` writes one handoff, the phase the runner was given, under the record lock. Slug checks still refuse `../`, absolute paths, and NUL before a path is built (ATTACK-001 denied). Summary YAML loading disables aliases, caps a handoff at 256 KB, and reports a parse failure as `unreadable` (ATTACK-011 denied). `Display.safe` replaces `\p{Cc}`, `\p{Cf}`, `\p{Zl}`, and `\p{Zp}`, so the new `blocked:` line, the `warn:` line, the summary, and the vocabulary refusal cannot be forged with an escape, a carriage return, a newline, or a bidi override (ATTACK-002 denied). The `blocked:` line interpolates a phase id and an integer count.

`protection stated` is structure only, as REQ-013 and the rule's Limits section require. A boilerplate note, a list-valued note, and `protection: in_force` on a check whose result is `failed` all pass. Those are the accepted limit (THREAT-006), recorded for judgment, not a new hole beyond the specification. Review of a later change that touches an `access_control` path still has to read the notes; this change touches none.

The runner does not clear or rewrite `blocking` when it marks a phase (ATTACK-003 denied). Two finishes serialize on the record lock (ATTACK-004 denied).
