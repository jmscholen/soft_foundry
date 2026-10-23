# Threat Model

The product is a local CLI (Ruby) that edits a change record in a Git working tree. There is no network listener, tenant, database, or credential store introduced; the attackers are (a) an agent in a phase session trying to escape its skill, (b) a hurried or careless person or script, and (c) a contributor trying to land a record that looks finished. Categories without a surface are marked N/A with a reason.

## Trust boundaries
See `trust-boundaries.md`: TB-1 runner and session, TB-2 CLI arguments, TB-3 the record on disk, TB-4 parallel siblings, TB-5 `--env` secrets, TB-6 CI on `main`.

## Externally controlled inputs
- `phase reopen --reason`, `change release --item ID=DESC`, `change discharge ID --note`: free text written into YAML and echoed to output.
- `phase run --env NAME=VALUE`: names and values, values may be credentials, `{phase}` expansion.
- Phase names on the command line (`--parallel` list).
- The session marker environment variable, read by the guard.
- `.ai/workflow.yml` `isolated_phases`, read by the CLI and guard; and the judgment evidence read by `release` (undischarged items).
- Existing record state: handoff statuses and commit shas.

## Authorization boundaries
No users or roles exist. Authorization is by who may invoke a command: a person may run everything; a phase session may do only its skill's work. The enforcement is the session marker (refusal of lifecycle-rewriting commands) plus the guard. Bash is checked against deny sets only, so a session can run commands the guard cannot see; the marker refusal inside the commands is therefore a second line, and neither is a hard sandbox.

## Abuse cases
- AC-A1 A session runs `soft-foundry phase reopen` to reset a sibling or earlier phase, or to erase a failed verdict and rerun until it passes.
- AC-A2 A session unsets or rewrites the marker in its Bash command (`env -u`, `VAR=review soft-foundry ...`) to run reopen/release, or to make the guard check it against a more permissive skill.
- AC-A3 An implementing session forges a finished change: edits handoffs to `complete` by hand, then runs `change release` with one throwaway item so `main` CI passes without evidence.
- AC-A4 Release then never discharge: the record sits `released` forever, hiding owed work, and `ci` keeps passing.
- AC-A5 Release drops judgment `undischarged` items by not carrying them over, or renames them.
- AC-A6 Auto-reopen on a stale phase is triggered by a trivial commit to throw away a good verdict, or to launder a phase: stale evidence reset then rerun by the same session that implemented.
- AC-A7 `--env` value (a database URL with a password) leaks via the record, a `ps` listing, an error message, or a shell transcript.
- AC-A8 A crafted reason, item description, or note containing newlines, YAML syntax, ANSI escapes, or `warn:`-looking lines injects keys into the record or spoofs log output.
- AC-A9 `{phase}` expansion or a `SOFT_FOUNDRY_*` name overrides the marker or other runner variables.
- AC-A10 Two parallel sessions, or a parallel run and a person, write the record at once and lose an update; or a crash leaves half a reset.
- AC-A11 A parallel session commits, moving HEAD so sibling evidence binds to different commits; or two sessions write the same file.
- AC-A12 A non-isolated phase (implement, review, judge) is slipped into `--parallel` via a name alias or a case variant.
- AC-A13 A record with a malformed or empty `release` block, or `status: released` set by hand, is merged to bypass the closed requirement.

## Injection / XSS / CSRF / SSRF / file risks
- Injection: YAML and log injection through free text (AC-A8); command injection through `--env` is N/A because values are passed in an environment hash, not interpolated into a shell string; this must hold in the implementation and is an attack case.
- XSS: the UI shows released status and open-item descriptions (REQ-025); item descriptions and reasons are attacker-influenced text and must be HTML-escaped. This is real, since the UI is a loopback page that renders record text.
- CSRF: the UI is read-only; the change adds no mutating endpoint, so N/A. The attack phase should confirm no write route was added.
- SSRF: no outbound requests; N/A.
- File: atomic write and lock file in the record directory: a symlinked or pre-created lock file, or a stale lock, could block or redirect writes (THREAT-009). Reopen must not write evidence files or follow symlinks out of the change directory.

## Resource exhaustion and DoS
- Lock wait bounded to 10 s; a stale or held lock must fail, not hang (THREAT-009).
- Parallel run: N sessions but the isolated list is two phases, so concurrency is bounded by the list; an interrupt must signal all children and not orphan them.
- Text caps of 500 characters bound record growth; `phase_reopenings` grows without bound by repeated reopen but each entry is small. Accepted.

## Infrastructure exposure
None: no deployed service, IaC, or listener. The only exposed thing is CI reading the record. `surfaces.infrastructure` is false.

## Proposed attack cases
- PAC-01 In a session with the marker set, run `phase reopen`, `change release`, `change discharge`: each refuses and writes nothing. Repeat with the marker unset via `env -u` and report what the tool does (expected: not detectable; document the residual).
- PAC-02 Set the marker to a non-isolated phase, to an unknown phase, to an empty string, to a mixed-case phase, and to `../x`: the guard reports each per `enforcement.yml`.
- PAC-03 Hand-edit all handoffs to complete with no evidence, then `change release --item X=y`: refused by the judgment and gate checks, or the gap is reported.
- PAC-04 Release with a judgment that has `undischarged` items: all appear as open items under their ids; `discharge` of a carried item works; close refuses until all are discharged.
- PAC-05 Merged record with `status: released` and no `release` block, empty items, or all discharged: `check` or `ci` fails.
- PAC-06 Reason, item description, and note with newline, `\e[31m`, `: `, `---`, a 501-character string, and a NUL byte: refused or stored inert; the YAML round-trips.
- PAC-07 `--env DB_URL=postgres://u:secret@h/{phase}`: grep the record, handoffs, stdout, stderr, error output, and `ps` for `secret`. Also `--env SOFT_FOUNDRY_PHASE=review`, `--env lower=1`, `--env 1A=1`.
- PAC-08 Run two parallel stubs that both rewrite the record, killing one mid-write: YAML parses, no lost update, no half reset. Hold the lock file from another process: fails within about 10 s naming the lock. Pre-create the lock as a symlink.
- PAC-09 `--parallel` with implement, review, judge, a duplicated phase, a mixed-case name, and one phase only: nothing starts, nothing written.
- PAC-10 Parallel session that commits: warn and non-zero exit; other sessions' evidence still bound to start HEAD.
- PAC-11 Stale auto-reopen: commit an unrelated file, `phase run` a complete phase: reset with source `auto` and a labelled line; confirm a current phase is still refused and a closed or released record resets nothing.
- PAC-12 Item description containing `<script>` is rendered escaped in the UI and in snapshot HTML.
- PAC-13 Reopen of `specify` on a locked specification resets everything downstream and leaves evidence files byte-identical; reopening with a record in closed/released/exploring/awaiting_human is refused.
