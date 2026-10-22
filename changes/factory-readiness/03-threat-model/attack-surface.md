# Threat Model

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
- Case files under `.ai/harness-evals/cases/` (anyone who can open a pull request): ids, paths, file contents, handoff keys, regular expressions.
- `metadata.yml` of a change: `risk`, `skipped_phases`, and their spelling.
- Handoff files written by agent sessions: `commit_sha`, `executed_by`, `findings`.
- Files under `02-specification/` after the lock.
- Command-line values: `--case`, `--shell`, anything after `--`.
- The environment of whoever runs a command: `LANG`, `SOFT_FOUNDRY_GUARD`.
- Live eval output: whatever a coding shell writes into the scratch record.

## Authorization boundaries
Skill permissions as declared, enforced by the guard in block mode (REQ-FR-004); the guard's own configuration and the eval cases are outside every skill (MIT-001, MIT-003). `change close` and the gate decide what a record may waive (MIT-004).

## Abuse cases
- A steered implementing session turns the guard off by writing its override or hook file (THREAT-001).
- A case writes outside the scratch repository through a `..` path, or carries instructions for the reviewer session (THREAT-002).
- The implementer reads or edits the cases (THREAT-003).
- A record waives judgment, or sets a risk that lets it waive attack and review, and closes (THREAT-004).
- Criteria are edited after evidence exists and the specify handoff re-stamped (THREAT-005).
- Scratch repositories pile up after exceptions; live sessions run without bound (THREAT-006).
- A planted secret shape reaches a committed file or a log (THREAT-007).

## Injection / XSS / CSRF / SSRF / file risks
File: case paths (THREAT-002). Injection: case content as reviewer instructions (THREAT-002); the phase prompt itself is fixed and names no case content. No network, markup, or request surface; `eval` makes no outbound call.

## Resource exhaustion and DoS
THREAT-006: a crashing case, an unbounded live run, an oversized case.

## Infrastructure exposure
N/A: no deployed service; CI runs `ci`, which gains the deterministic cases.

## Proposed attack cases
ATTACK-001 each guard-configuration path through Edit, Write, and Bash in block mode, from the implementation skill and from the review skill; ATTACK-002 a case with `../escape`, an absolute path, and a symlink target, plus a case whose planted file carries an override phrase (`check` must warn); ATTACK-003 Read, Edit, and `cat` of a case from the implementation skill; ATTACK-004 `skipped_phases` naming judge, review, and attack on medium risk, with risk blank, `LOW`, and `unknown`, then `change close` with and without `--force`; ATTACK-005 edit `02-specification/requirements.yml` after verification and re-stamp the specify commit; ATTACK-006 a case whose handoff is invalid YAML and a case with 500 files, checking the temp directory afterwards; ATTACK-007 the planted-secret case's output and this record's evidence, scanned.
