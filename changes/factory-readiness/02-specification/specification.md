# Specification

## Intent
Make Soft Foundry something an application repository can install and rely on: the gate refuses what it should refuse, that refusal is measured by an executable eval suite that ships with the control plane, evidence phases prefer a fresh session and say when they did not get one, the guard refuses rather than warns, the specification is locked on the gated track, required phases cannot be waived without the risk allowing it, every file is read as UTF-8, and the whole lifecycle is proven end to end against a Rails-shaped application repository. Requirements are REQ-FR-001 through REQ-FR-010 in `requirements.yml`; acceptance criteria are AC-FR-001 through AC-FR-021 in `acceptance-criteria.yml`.

## Personas and authorization boundaries
- **Maintainer** of an application repository: runs `soft-foundry init`, `eval`, `ci`, `doctor`; decides risk and waivers; accepts residual risk. The only person who may use the machine-local guard override.
- **Implementing agent** (coding shell under the implementation skill): writes application and test code and `05-implementation/`; cannot write evidence, `.ai/`, or `README.md`, and under block mode is refused when it tries.
- **Evidence agents** (verification, evaluation, attack, review, judgment): ideally fresh sessions launched by `phase run`; may read what their permissions allow; no skill may read `.ai/harness-evals/`.
- **CI**: runs `rake test` and `rake ci`; `ci` includes the deterministic evals.

## Functional behavior
- **UTF-8 (REQ-FR-001).** Every file the library reads for content (gate, advisory, scan, learning, UI assets, maturity scan, record templates) is decoded as UTF-8 whatever `LANG` is. A file that is not valid UTF-8 is scrubbed (invalid bytes replaced), never a crash. The suite passes under `LANG=C`.
- **Specification lock on the gated track (REQ-FR-002).** When the specify phase is complete and the change is not vetted, the `specification locked` check compares `02-specification/` against the specify handoff's `commit_sha` (committed and uncommitted changes) and fails on any difference, naming the files and the way forward: rerun the specification phase as a recorded requirement change. Every commit-bound phase's `evidence current` check also fails when `02-specification/` changed after that phase's own `commit_sha`, because its evidence was about the earlier criteria. The vetted path is unchanged.
- **Fresh-context advisory for every evidence phase (REQ-FR-003).** The advisory that today names a review or judgment completed without `phase run` names every completed phase whose skill declares `evidence: commit_bound` and whose handoff lacks `executed_by.fresh_context: true`. The verification, evaluation, and adversarial-testing skills say that the phase prefers a fresh session.
- **Block mode (REQ-FR-004).** `.ai/policies/enforcement.yml` declares `guard.mode: block`, so a fresh `init` installs block mode. `hooks install` and `doctor` print the mode in effect and its source. A refusal line names the tool, the path, the skill, the mode, and the policy file, and says that the machine-local override exists; it never names what the override should be set to.
- **Harness evals, deterministic (REQ-FR-005).** `.ai/harness-evals/cases/<id>.yml` declares a case: `id` (equal to the file name), `kind: gate`, `description`, a `record` (risk, phases to complete at HEAD with templates filled, phases to waive with a rationale, handoff keys to merge, files to write into the record), optional `repository` files to write into the scratch repository after the record is complete (with or without a commit), and `expect` (`phase`, optional `check` naming a `Gate::CHECKS` key, `outcome` pass or fail). `soft-foundry eval [--json] [--case ID]...` builds, for each case, a scratch git repository under the system temp directory carrying a copy of this repository's `.ai/`, scaffolds the record with `ChangeRecord.create`, applies the case, runs `Gate#evaluate(phase)`, compares, and deletes the scratch repository. Output is one line per case with a status word, then one summary line; exit 0 when every run case passed, 2 otherwise. `ci` runs the deterministic cases after the control-plane check and before the records, and fails when one fails. The suite ships at least nine planted defects and one well-formed control.
- **Harness evals, live (REQ-FR-006).** A case with `kind: live` declares `phase` (a lifecycle phase; `review` in the shipped cases), `application.files` to write into the scratch repository before the record exists, a `record` as above, and `expect.finding`, a regular expression. `soft-foundry eval --live --shell <claude|codex|grok> [-- shell args...]` runs such a case by invoking `phase run <phase> --shell <shell>` in the scratch repository, then reads the phase's handoff `findings` (summary and failure) and the phase directory's Markdown files; the case passes when the pattern matches. The output line records the shell, the `resolved_model` the session wrote, and the finding ids matched. Without `--live`, a live case is reported `skip` with the command that would run it. A live case whose session exits non-zero, or whose gate fails afterwards, is reported `error` with the exit status and counts as a failure. Nothing is written into `.ai/` or any change record.
- **Waivers by risk (REQ-FR-007).** `.ai/workflow.yml` declares `waivable_by_risk`, a map from risk to the lifecycle phases a change of that risk may name in `skipped_phases`. The gate's first-phase check `waivers permitted` fails when `skipped_phases` names a phase that is not globally optional and not in the list for the change's declared risk, or names `review` or `judge`, which no risk may waive; an undeclared or unknown risk may waive nothing but optional phases. `soft-foundry check` fails a control plane whose `waivable_by_risk` names an unknown phase or names `review` or `judge`. `change close` refuses (exit 1, naming the phase) when the judge phase is not `complete`, unless `--force`. The shipped default is `low: [discover, specify, threat_model, plan, attack, learn]`, `medium: [discover, plan]`, `high: []`.
- **Application-repository proof (REQ-FR-008).** A test builds a Rails-shaped repository (a `Gemfile` naming `rails` and `rspec`, `config/application.rb`, `app/models/user.rb`, `app/controllers/users_controller.rb`, `db/schema.rb`, `spec/models/user_spec.rb`, a `README.md`), runs `init` from this repository's source, and asserts: the profile records `rails` and `rspec`-style testing; `change new` on a change branch declares `surfaces.accessibility: true`; `check` passes; the guard under the implementation skill allows `Edit app/models/user.rb` and `Edit spec/models/user_spec.rb`, refuses `Edit .ai/rules/rails.md`, `Edit changes/<slug>/06-verification/results.md`, and a `Read` of `.ai/harness-evals/README.md`, and refuses a `Bash` command naming `.ai/policies/enforcement.yml`; the installed policy is block mode; `gate intake` passes on a filled intake; and `eval` passes in that repository using its installed control plane. The same journey is run by hand and its transcript is evaluation evidence.
- **Documentation (REQ-FR-010).** README (a new "Proving the gate: harness evals" section; the guard section says block; the lifecycle section says which phases a risk may waive and that judgment is never waived; the specification section says the gated track locks at the specify commit), `soft-foundry help`, `.ai/schemas.md` (the new checks, the eval case schema, `waivable_by_risk`), `.ai/README.md` (`harness-evals/` row), `AGENTS.md` (judgment never waived; waivers by risk), `.ai/harness-evals/README.md` (how to write a case). Version 0.21.0.

## Accessibility
REQ-FR-009. Every new line printed by `eval`, `gate`, `check`, `change close`, `hooks install`, `doctor`, and the guard carries its outcome as a word (`pass`, `fail`, `skip`, `error`, `warn`) at a fixed position, does not depend on color, glyph, or width, and is ASCII apart from the existing status glyphs. `eval --json` gives the same facts as data. Error messages say what to do next. Nothing prompts.

## Data and consistency
- Eval scratch repositories live under `Dir.mktmpdir` and are removed when the case ends, including on failure. They never hold a real secret: a planted secret is a canary shape and the case's expectation names it.
- The profile `.ai/repository.yml` is written only by discovery (this change's) and the maturity block only by `score_maturity`.
- Handoffs written by `phase run` keep `executed_by` as today; the advisory reads it and never writes.

## Failure behavior
- A case file that does not parse, lacks a required key, names an unknown phase or check, or has an invalid regular expression: `check` reports an error naming the file and the key; `eval` reports that case as `error` and continues with the rest.
- A live case without `--shell`, or with a shell not on `PATH`: reported `error` naming the flag or the shell; exit 2.
- A gate crash inside a case (an exception) is reported as `error` with the exception class and message, never a backtrace, and the scratch repository is still deleted.
- `change close` without a completed judgment: exit 1, one line naming `14-judgment` and `--force`.
- A guard refusal in block mode: exit 2 with the reason on stderr, as today.

## Security requirements
- Block mode is the packaged default; the override order (environment, machine-local file, policy) is unchanged and documented.
- No skill gains read or write access to `.ai/harness-evals/`; `check` still requires every skill to deny it. `eval` prints case ids and outcomes, never case content.
- Live eval sessions run as the user with the host's own permission mode, as `phase run` does; the case runs in a scratch repository, so a steered session can write only there. The README says so.
- The content scan applies to eval case files as to the rest of `.ai/`: a planted secret in a case must carry the `soft-foundry:scan-allow` marker or a `content-scan.yml` entry with a reason.

## Privacy and security policy conformance
Nothing the published policies cover changes: the repository records privacy, security, and terms as NOT_APPLICABLE (developer tool, no service). `eval` makes no network call; a live eval's coding shell makes the same provider calls `phase run` already makes. `surfaces.policy` stays false.

## Performance and resource limits
- A deterministic case completes in under ten seconds on the CI runner (a scratch repository, two or three git commands, one gate run); the shipped suite of about ten cases adds well under a minute to `ci`.
- A live case is bounded by the shell session; `eval --live` runs cases sequentially and prints each as it finishes.

## Infrastructure implications
None. CI already runs `rake ci`.

## Observability expectations
- `eval` output (one line per case, one summary) is the operator surface; `--json` carries the same with `version: 1` and `stable: false`.
- The guard log (`.soft-foundry/guard.log`) records block-mode refusals as it records warnings today.
- The fresh-context advisory makes an in-session evidence phase visible on every gate run, `change status`, `ci`, and `change close`.

## Acceptance criteria
See `acceptance-criteria.yml`: AC-FR-001 through AC-FR-021, each mapped to a requirement and to be bound to tests, EVAL ids, and ATTACK ids by later phases.
