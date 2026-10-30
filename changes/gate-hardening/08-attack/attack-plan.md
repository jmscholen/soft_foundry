# Attack Plan

## Intent to challenge
`soft-foundry phase seal` and the seven gate checks this change adds (REQ-001 to REQ-036) exist so that a hollow record cannot pass as a recorded one: a phase enters history only through the tool, after its gate; a sealed phase's evidence is bound to a commit that follows its predecessor's and reaches the branch tip; structured files parse; a failing test is named; a criterion is checked or set aside with a reason; evidence matches its manifest; a judgment says one word; review and judgment carry the runner's stamp in block mode. This phase tries to make each of those claims false while the gate still passes, to make the sealing command commit the wrong thing (another record's content, another branch's history, uncommitted code, a planted file), to leave the record half-sealed, and to make the gate crash, hang, or leak.

Check size: `soft-foundry change size --phase attack` reports `full_route_sweep` (whole repository, no scope declared). The "routes" of a CLI are its commands and checks: every new refusal of `phase seal`, every new check, `phase run --parallel`'s sealing path, `change close`, `change summary`, and the `ui` snapshot were attacked, plus the pre-existing record lock and safe-write code the seal now depends on.

## Threats mapped
| Threat | Cases | Mitigation under test |
| --- | --- | --- |
| THREAT-001 session seals another phase | ATTACK-001, ATTACK-021 | MIT-001 session marker |
| THREAT-002 forged `executed_by` | ATTACK-006 | MIT-002 (accepted boundary; ledger cross-check) |
| THREAT-003 commit_sha replay | ATTACK-005 | MIT-003 `commit lineage` |
| THREAT-004 manifest path escape | ATTACK-004 | MIT-004 realpath containment, regular-file test |
| THREAT-005 failing test recorded as acceptable | ATTACK-016 | MIT-005 `test results recorded` |
| THREAT-006 criterion set aside without a reason | ATTACK-017 | MIT-006 `criteria covered` |
| THREAT-007 symlinked record file | ATTACK-002, ATTACK-003 | MIT-007 `RecordFile` |
| THREAT-008 gate raises instead of refusing | ATTACK-018 | MIT-008 fail-closed lines |
| THREAT-009 phase never recorded | ATTACK-011 | MIT-009 `predecessor complete` requires `recorded_commit` |
| THREAT-010 slow or large gate | ATTACK-012 | MIT-010 bounded parse set |
| THREAT-011 concurrent seals, held or symlinked lock | ATTACK-008, ATTACK-009, ATTACK-010 | MIT-011 record lock, git index lock |
| THREAT-012 kill mid-seal | ATTACK-007 | MIT-012 idempotent rerun, fail-closed downstream |
| THREAT-013 seal onto the wrong branch | ATTACK-014, ATTACK-021 | MIT-013 branch check |
| THREAT-014 leak through output | ATTACK-013, ATTACK-015 | MIT-014 redaction, text-node rendering |
| THREAT-015 turn the fresh-session check off | ATTACK-019 | MIT-015 repository policy only |
| (not in the model) seal entry, verdict, close, smuggled metadata | ATTACK-020, ATTACK-022 | REQ-002, REQ-013, REQ-017, REQ-033 |

## Adversarial journeys
Every case runs against a scratch git repository under `/tmp/sf-attack2/repos/` built by `evidence/scripts/build.rb`: a copy of this repository's `.ai/` control plane, a record `c1` on branch `change/c1`, and the phases through verify (or further, per case) completed the way the suite's fixture completes them and committed by hand, nothing sealed yet. The branch's own code runs through `evidence/scripts/sf` (`ruby -I<lib> exe/soft-foundry` with every `SOFT_FOUNDRY_*` and provider variable unset) or `sf-env` when a case sets `SOFT_FOUNDRY_PHASE` on purpose. `evidence/scripts/batch*.sh` are the exact commands; each case's transcript is the evidence file `cases.yml` names. For each case `cases.yml` records the threat, the attempted violation, the starting privilege, the steps, the expected denial, the observed result, and the evidence.

Journeys, in the order the threat model's abuse cases list them: record a failure as a pass (ATTACK-016, ATTACK-017); move the staleness baseline (ATTACK-005, backward and forward); skip a phase's history (ATTACK-011); look like a fresh session (ATTACK-006, ATTACK-019); seal someone else's phase or record (ATTACK-001, ATTACK-014, ATTACK-021); make the gate read outside the record (ATTACK-002, ATTACK-003, ATTACK-004); make it crash or hang (ATTACK-018, ATTACK-012, FIFO and 200 MB artifacts in ATTACK-004); race or kill the seal (ATTACK-007, ATTACK-008, ATTACK-009, ATTACK-010); leak through output (ATTACK-013, ATTACK-015); smuggle through the seal commit (ATTACK-020); and the seal entry's own refusals (ATTACK-022).

## Rerun after the third remediation pass
This run is the rerun after `09-remediation`'s second and third passes (GREEN `39d7e4f` for ATK-010 to ATK-013, ATK-006 and ATK-007; GREEN `c664d12` for EVAL-017 and EVAL-018). Every earlier case was run again unchanged (`evidence/scripts/batch1.sh` to `batch6.sh`; transcripts replaced) to show which findings the fixes closed. New cases attack the fixes themselves: ATTACK-026 (the seal's commit subject forged on a hand commit; the policy and metadata remediations; `gate all` cost), ATTACK-027 (the smallest "rerun" that licenses a moved `commit_sha`; the policy shape), ATTACK-028 (a scalar `guard`), and ATTACK-029 (a hand-committed phase reported `already sealed`). `batch7.sh` to `batch9.sh` are the new commands. The scripts hard-code `/tmp/sf-attack2/` and `ruby` 3.3.1 from asdf.

## Safety boundary
Target: this repository's own code at commit 47583ef (the remediated code after the third pass; earlier attack runs were at 303a48f and 5db4836), run only against throwaway repositories under `/tmp/sf-attack2/` on this machine. No production system, no third party, no network, no credential: the one "secret" is the literal `hunter2` passed to `--env` in a scratch run, and the fake `claude` shell on `PATH` for ATTACK-008 and ATTACK-013 is a three-line script that never calls a provider. Destructive actions (SIGKILL of a sealing process, deleting a branch, planting symlinks and FIFOs, removing `.git/index.lock`) were performed only inside the scratch repositories. Nothing in this repository outside `changes/gate-hardening/08-attack/` was written; no commit was made; the parallel evaluation phase's files were not touched. Production/third-party destructive or security testing requires explicit authorization and was neither requested nor performed.
