# Attack Plan

Commit under attack: `06a4830966d32fb135267d5160ab038af216c0b0` (branch `change/init-command`). Every case was executed while HEAD was `a733f84086d099ae48a209725d3ae037806c96dc`; the concurrent evaluation phase then committed `06a4830`, which touches only `changes/init-command/07-evaluation/`. `git diff --stat a733f84..06a4830 -- lib exe test soft_foundry.gemspec .ai` is empty, so the product code attacked is byte-identical at both commits.

## Intent to challenge
`soft-foundry init` claims to be safe on first run, idempotent afterwards, confined to the target root, and incapable of destroying user-owned content without `--force`. The specification's controls are the SHA-256 ownership manifest, root confinement with symlink refusal, the conflict/`--force` rule, uncommitted-edit protection, the failure classification that tells a maintainer whether to look at their repository or file an upstream issue, and the onboarding step that writes machine-local state. The specification handoff (SPEC-002) asks that the manifest trust decision, `--force`, and root confinement be attacked first; that ordering was followed. The attack tried to make the installer write outside the root, overwrite content it must not touch, misreport what it did, hang, or hand a maintainer a diagnostic that leaks. It also tried surfaces the threat model did not enumerate: the predictable temp-file sibling used by the atomic write, the unguarded `.soft-foundry/` directory, git-ignored managed paths, redirected (rather than emptied) path-group overrides, and the `models` command as a second consumer of provider-derived strings.

## Threats mapped
Every threat with `attack_case_required: true` in `03-threat-model/threats.yml` has at least one executed case; THREAT-003 and THREAT-007 (not required) were exercised as well. Proposed case ids in `attack-surface.md` were renumbered because several threats needed more than one case.

| Threat | Mitigation | Cases | Outcome |
| --- | --- | --- | --- |
| THREAT-001 symlink escape | MIT-001 | ATTACK-001, 002, 003, 004, 005 | 001-003 denied; 004 and 005 violated |
| THREAT-002 packaged path traversal | MIT-002 | ATTACK-007 | denied |
| THREAT-003 tampered control plane | MIT-003 | ATTACK-020 | denied; residual confirmed |
| THREAT-004 manifest forgery | MIT-004 | ATTACK-008, ATTACK-021 | 008 denied (design-accepted residual confirmed); 021 violated |
| THREAT-005 manifest scope creep | MIT-005 | ATTACK-009 | denied |
| THREAT-006 `--force` scope creep | MIT-006 | ATTACK-010, ATTACK-021 | 010 denied; 021 violated |
| THREAT-007 TOCTOU / concurrent runs | MIT-007 | ATTACK-017 | denied (lock); plan-to-write seam not attacked, see safety boundary |
| THREAT-008 wrong root | MIT-008 | ATTACK-011 | denied; two mitigation gaps recorded |
| THREAT-009 marker spoofing / prompt injection | MIT-009 | ATTACK-012 | denied; observations recorded |
| THREAT-010 untrusted `repository.yml` overrides | MIT-010 | ATTACK-013 | violated |
| THREAT-011 `.gitignore` neutralization | MIT-011 | ATTACK-014, ATTACK-005 (14c) | 014 denied; local-exclude gap recorded |
| THREAT-012 diagnostic leakage / misclassification | MIT-012 | ATTACK-015 (plus 006, 009, 013 cross-references) | violated |
| THREAT-013 partial writes | MIT-013 | ATTACK-016 | denied |
| THREAT-014 resource exhaustion | MIT-014 | ATTACK-006, 009, 018 | 006 violated (hangs); 009 and 018 denied with gaps |
| THREAT-015 provider-response injection | MIT-015 | ATTACK-019 | violated (via `models`) |

## Adversarial journeys
Full steps, observed results, and evidence paths are in `cases.yml`; outcomes are tabulated in `results.md`. Summary of each journey:

| Case | Threat | Attacker / start state | Attempted violation | Expected safe behavior | Result |
| --- | --- | --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | PR author; `.ai -> outside dir` | write outside root through the top-level link | refused, exit 1, nothing written | denied |
| ATTACK-002 | THREAT-001 | PR author; `.ai/rules -> outside`, `.ai/skills -> ../docs/skills` | write through a subdirectory link, outside and inside the root | refused before any write | denied |
| ATTACK-003 | THREAT-001 | PR author; links at `.ai/workflow.yml`, `AGENTS.md`, `CLAUDE.md`, `.gitignore`, `changes/README.md`, `docs/user/README.md`, dangling `AGENTS.md`, `docs -> outside` | overwrite or create an outside file through a file link, also with `--force` | refused, victims unchanged | denied |
| ATTACK-004 | THREAT-001 | PR author; symlinks at `<managed>.soft-foundry-tmp` | make the atomic write follow the temp sibling | temp path guarded like the destination | violated |
| ATTACK-005 | THREAT-001 | PR author; `.soft-foundry` dir symlink, `runtime.yml`/`init.lock` symlinks, hardlink | make the lock and `runtime.yml` writes leave the root (init and onboard) | `.soft-foundry/` guarded like managed paths | violated |
| ATTACK-006 | THREAT-014 | local user; FIFOs at eight managed and state paths | hang init | prompt target-side refusal | violated (two hangs, one exit 4) |
| ATTACK-007 | THREAT-002 | supply chain; tampered packaged copies | write outside root from the package; false positives on `..` names | exit 4, nothing written | denied |
| ATTACK-008 | THREAT-004 | PR author; forged manifest for a hardened file, committed and uncommitted | revert hardening without a conflict | committed: `updated` (accepted); uncommitted: `conflict` | denied |
| ATTACK-009 | THREAT-005/014 | PR author; manifest entries outside `.ai/`, non-canonical, alias bomb, 26 MB, directory, bad bytes/types | act on or delete unmanaged paths; hang | validated, ignored, or refused target-side | denied |
| ATTACK-010 | THREAT-006 | hurried agent; `--force` with pointer, state, scaffold, `.gitignore`, symlinked, uncommitted conflicts | extend `--force` beyond `.ai/` conflicts | only `.ai/` conflicts forced | denied |
| ATTACK-011 | THREAT-008 | agent/env; `--root` sub/other/parent/`-x`/``/`/`, `GIT_DIR`, `GIT_WORK_TREE`, `GIT_CEILING_DIRECTORIES`, fake HOME | install elsewhere | top-level required, root printed, env ignored | denied |
| ATTACK-012 | THREAT-009 | PR author; bare, fenced, wrapped, byte-0, CRLF, legacy, injected pointer files | suppress the bootstrap while reporting success | skipped only for the verbatim block | denied |
| ATTACK-013 | THREAT-010 | PR author; `repository.yml` overrides that empty or redirect groups | neutralize staleness and eval denial | check warns naming the groups | violated |
| ATTACK-014 | THREAT-011 | PR author/maintainer; `!.soft-foundry/`, local excludes, symlinked state dir | get local state committed | `conflict` when not effective | denied |
| ATTACK-015 | THREAT-012 | passive; canary keys in env, eight failure conditions, cwd != root, fake HOME | leak keys or absolute paths; mislabel target faults | fixed diagnostic, relative paths, correct class | violated |
| ATTACK-016 | THREAT-013 | environment; injected ENOSPC, `kill -9` mid-write and mid-append | truncated files, bare marker, stale manifest | temp-and-rename, manifest last, honest rerun | denied |
| ATTACK-017 | THREAT-007 | concurrent process; two simultaneous inits x4 | corrupt the manifest | lock refuses the loser | denied |
| ATTACK-018 | THREAT-014 | PR author/supply chain; 512 MiB canonical, target, 256 MiB pointer/.gitignore | exhaust memory or time | streaming, size caps | denied with gaps |
| ATTACK-019 | THREAT-015 | compromised provider (stubbed in-process) | forge or hide report lines, plant escapes in `runtime.yml` | sanitized everywhere | violated via `models` |
| ATTACK-020 | THREAT-003 | supply chain; tampered `.ai/README.md` and AGENTS interior | persist attacker text past the next legitimate run | `updated`/`conflict`, never `skipped` | denied; residual confirmed |
| ATTACK-021 | THREAT-004/006 | PR author + maintainer; git-ignored `.ai/rules/`, `--allow-non-git` in a git repo | overwrite an unrecoverable uncommitted edit | never overwritten, as the report promises | violated |

## Safety boundary
All work stayed inside the authorization envelope recorded verbatim in `cases.yml` and `results.md`: targets were throwaway git repositories and tampered packaged copies under a `mktemp -d` directory beneath the session scratchpad; data was synthetic; the five `*_API_KEY` variables present in the invoking environment were unset for every run (`env -u`), and the only keys ever set were literal `*-attack-canary-*` strings under `--no-onboard` or an in-process `Net::HTTP.start` stub, so no network connection was attempted; no path under the real home directory, no other repository, no system configuration, and no elevated privilege was touched; the scratch tree was deleted at the end. Three actions were deliberately not performed because they would leave the envelope: a real (non-dry-run) `init --root / --allow-non-git`, a real install into the maintainer's `$HOME` (simulated with `HOME=<scratch>` instead), and the threat model's proposed THREAT-007 plan-to-write swap, which needs a test seam inside the write stage and would have meant modifying code; concurrency was attacked with the lock instead. Provider-response injection was executed offline by stubbing `Net::HTTP.start` in a scratch script that requires the untouched library, which is within the envelope (no network, no code change). No model-provider refusal occurred. One scope incident happened and is recorded in `handoff.yml` notes: a fixture command in the first ATTACK-012 attempt ran before its `cd` and created an untracked `CLAUDE.md` in this repository's root; it was removed, and `git status` outside `08-attack/` was verified empty afterwards.
