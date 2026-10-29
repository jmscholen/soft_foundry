# Threat Model

## Trust boundaries
Seven, in `trust-boundaries.md`. The two that matter most are TB-2 (a record becomes history only through `phase seal`, which gates first) and TB-4 (a committer can write anything; the gate's job is to make a hollow record a visible act rather than an accident).

## Externally controlled inputs
Everything the gate and the sealing command read is written by a session or a committer:
- `handoff.yml`: `status`, `commit_sha`, `blocking`, `findings`, `executed_by` (meant to be runner-written), `branch_resolved` (meant to be seal-written), `panel`.
- `metadata.yml`: `git.branch`, `git.worktree`, `status`, `scope`, `skipped_phases`, `release`, `current_phase`.
- `02-specification/acceptance-criteria.yml` (`criteria[].id`), `06-verification/tests.yml` (`checks[]`, `size`, `full_suite`), `07-evaluation/journeys.yml` (`journeys[].criteria`), `14-judgment/evidence.yml` (`criteria_not_covered`), `evidence/manifest.yml` (`artifacts[].path`, `sha256`), the files those paths name, `14-judgment/final.md` (the `## Outcome` section).
- Command arguments: `--change SLUG`, `--type=`, `--risk=`, `--env NAME=VALUE`.
- Environment: `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL`, `SOFT_FOUNDRY_GUARD`, provider keys.
- Git state: refs (including a `git.branch` created after the evidence commit), the dirty tree, hooks, the index lock, `user.name`/`user.email`.
- Filesystem: symlinks at any record path, permissions, a kill signal at any instant.

## Authorization boundaries
- A session may seal only the phase it is running (TB-1). Nothing else distinguishes sessions; the guard's `SOFT_FOUNDRY_PHASE` marker is the only identity a session carries, and it can be unset by a shell (accepted in `phase-lifecycle-controls` as a guard against accident, not an adversary).
- The runner may seal any phase it ran (TB-3).
- A person may do anything (TB-4). The policy that protects `.ai/policies/**` from every skill does not bind a person.
- `change close --force` and `--no-verify` are a person's explicit override and are not threats; a committer using them is recorded as having done so.

## Abuse cases
Attacker goals, in the order a hollow record would try them:
1. **Get a failing or absent test recorded as a pass** (THREAT-005, -006). Write `result: pass` over a failure; write a passing `result` on a check that never ran; acknowledge a `fail` with a finding that names the check id in passing. The gate cannot tell; it can only insist the fail be named. Accepted boundary, stated in the check's `CHECKS` text.
2. **Move the staleness baseline back** (THREAT-003). Record an old `commit_sha` so later code is outside the measured range. Closed by `commit lineage`.
3. **Skip a phase's history** (THREAT-009). Complete a phase on disk, never commit it, carry on. Closed by `predecessor complete` requiring `recorded_commit`.
4. **Look like a fresh session** (THREAT-002). Hand-write `executed_by` with `fresh_context: true`. A committer can; the record then says the runner did something the ledger does not show. Accepted at TB-4, with the ledger as the cross-check a reviewer has.
5. **Seal someone else's phase** (THREAT-001, -013). Run `phase seal verify` from the implementation session; run `phase seal --change other` from a branch that is not that record's. The first is refused by the phase marker; the second by the branch check this model proposes (MIT-013).
6. **Make the gate read outside the record** (THREAT-004, -007). A manifest path of `../../`, an absolute path, or a symlink at `handoff.yml` pointing at another phase or outside the repository. Closed by realpath containment and symlink refusal.
7. **Make the gate crash or hang** (THREAT-008, -010). A YAML file that raises something other than `Psych::SyntaxError`; a `git:` that is a string; an alias-heavy YAML document; a manifest naming a very large file or a FIFO. Crashes are closed by REQ-021; the alias and size cases are bounded and carried.
8. **Race or kill the seal** (THREAT-011, -012). Two seals of the same phase at once; a `phase run` and a manual seal; a kill between the metadata write and the commit. The record lock serialises the writes; git's index lock serialises the commit; the kill leaves a state the idempotent rerun completes and downstream gates refuse until it does.
9. **Leak through output** (THREAT-014). An `--env` value appearing in a sealing message; a check detail carrying a key name from a hostile YAML file into `soft-foundry ui`. Closed by the existing redaction and escaping, re-verified for the new strings.
10. **Dodge the fresh-session rule by policy** (THREAT-015). Set `guard.mode: warn` in the repository policy, or an override on the machine. The override is ignored by the gate; the policy edit is a commit to a protected path that review sees.

## Injection / XSS / CSRF / SSRF / file risks
- **Injection into YAML parsing:** `YAML.safe_load` with `permitted_classes: [Time, Date]` instantiates no other class; `aliases: true` is needed by existing records and is bounded by Psych. The set of parsed files is fixed (required `.yml` files, `evidence/manifest.yml`); evidence bodies are hashed, never parsed.
- **Path traversal:** manifest paths are joined to the phase directory and `File.realpath`-checked to remain under it; absolute paths and `..` segments fail.
- **Symlinks:** `File.symlink?` is checked on each named record file before reading; a symlink fails the check or refuses the command.
- **Command injection:** every git call goes through `Git#run` with an argument array; no shell string is built from a record field. Commit messages are built from the slug and phase id, both already validated by `ChangeRecord`.
- **XSS:** `soft-foundry ui` renders check details; the new details contain repository-relative paths, ids, SHAs, class names and Psych messages. Psych messages can echo a token from the file (a key name). The page's existing escaping covers it; ATTACK-015 confirms with a `<script>` key.
- **CSRF, SSRF:** N/A. No browser-originated writes, no outbound requests.

## Resource exhaustion and DoS
- The pre-commit hook runs `ci` on every sealing commit: sixteen seals per change at about two minutes each today. Bounded by the number of phases; measured at evaluation (REQ-036). A follow-up may narrow what the hook re-runs.
- SHA-256 over every listed artifact on every gate of that phase: linear in evidence size; records to date hold kilobytes to low megabytes. A manifest naming a FIFO or a device would block; realpath containment keeps the path under the phase directory, and a regular-file check is cheap (MIT-004).
- `ancestor?` is two git subprocesses per phase: sixteen phases, under a second.
- An alias-heavy YAML document can expand in memory; Psych bounds nesting but not expansion. The parsed files are a committer's, under a record a reviewer reads. Carried as residual with that reasoning (THREAT-010).

## Infrastructure exposure
None. The gem has no service surface. GitHub Actions runs the suite; it does not run `phase seal`.

## Proposed attack cases
Required by `attack_case_required: true` in `threats.yml`; the adversarial-testing phase runs them against `phase seal` and the new checks on a scratch record, inside the guard where the case allows it and noting where it had to step outside:
- ATTACK-001 seal from a session whose `SOFT_FOUNDRY_PHASE` names another phase (THREAT-001).
- ATTACK-002 `handoff.yml` is a symlink to another phase's handoff; ATTACK-003 `metadata.yml` is a symlink (THREAT-007).
- ATTACK-004 manifest path `../../05-implementation/log.md`; ATTACK-004b an absolute path; ATTACK-004c a symlinked artifact (THREAT-004).
- ATTACK-005 `commit_sha` older than the predecessor's; ATTACK-005b `commit_sha` on an unreachable branch (THREAT-003).
- ATTACK-006 hand-written `executed_by` with `fresh_context: true` on review (THREAT-002; expected outcome: passes the gate, recorded as the accepted boundary, with the ledger cross-check shown).
- ATTACK-007 kill `phase seal` between the metadata write and the commit, then rerun (THREAT-012).
- ATTACK-008 two `phase seal` processes on the same phase at once; ATTACK-009 a held record lock; ATTACK-010 a symlinked lock file (THREAT-011).
- ATTACK-011 a phase committed with `--no-verify` and no seal, then the next phase gated (THREAT-009; expected: `predecessor complete` passes because the handoff is in history; the model accepts this: a committed handoff is recorded).
- ATTACK-012 a YAML file with 10,000 aliases to one anchor in `tests.yml` (THREAT-010; measure time and memory, record the bound).
- ATTACK-013 `phase run evaluate attack --parallel --env SECRET=hunter2` with a failing stub; grep all output (THREAT-014).
- ATTACK-014 `phase seal --change other` from a branch that is not `other`'s `git.branch` (THREAT-013).
- ATTACK-015 a `tests.yml` whose key is `<script>alert(1)</script>: 1`, gated, then viewed in `soft-foundry ui` (THREAT-014).
- ATTACK-016 `result: fail` acknowledged by a finding whose summary mentions the id in an unrelated sentence (THREAT-005; expected: passes; the accepted boundary, documented).
- ATTACK-017 `criteria_not_covered` reason of whitespace only, then of U+00A0 only (THREAT-006).
- ATTACK-018 `metadata.yml` with `git: a string` and with `git: []` (THREAT-008).
- ATTACK-019 repository policy `guard.mode: warn` committed by hand, then `gate review` (THREAT-015; expected: the check skips and the advisory prints; the policy edit is in the diff).
