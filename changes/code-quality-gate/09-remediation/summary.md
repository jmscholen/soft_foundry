# Remediation

## Finding references
- REV-001 (review, blocking): onboarding never turns the quality gate on in a newly initialized repository.

Round 1 of 2 (`remediation.max_rounds`).

## Root cause
`soft-foundry init` writes `.ai/repository.yml` from the profile template, whose `quality_gate` block is `enabled: false` with `set_by: null`. The scan kept any existing value whose `set_by` did not start with its own text, and a blank `set_by` does not, so the template's unset value was treated as a person's choice. The tests of the first implementation removed the key before scanning and so never met the template's value.

## Changes made
This is a fix: the specified outcome changes (REQ-004, AC-012).
- Contract: after `soft-foundry init` with a scan, or `soft-foundry onboard`, in a repository where Ruby, Python, JavaScript, TypeScript or PHP is detected, `quality_gate.enabled` is true unless a person set it. A person's value has a `set_by` that is not blank and that the scan did not write.
- Checks first, RED `55448aa`: two tests in `test/code_quality_gate_test.rb`. One scans over the template's unset value; one runs `init --maturity scan` on a new repository with a Gemfile. Both failed on the original code with `enabled` false where true was expected.
- Fix, GREEN (the commit after it): `MaturityScan#set_by_a_person?` in `lib/soft_foundry/maturity_scan.rb`; the comment in `.ai/templates/repository.yml` says what counts as a person's value.
- Rerun by this session, provider keys and SOFT_FOUNDRY_PHASE unset: `test/code_quality_gate_test.rb` 29 runs, 0 failures; `test/maturity_scan_test.rb` 11 runs, 0 failures; `test/cli_init_test.rb` 33 runs, 0 failures. The full suite was not rerun by this session.

Not changed: REV-002 to REV-008 are minor and are carried forward. `.ai/templates/repository.yml` is a control-plane file; it was edited under the maintainer's local warn override.

## Evidence invalidated
Verification and review (application code changed after the commits they describe).

## Required reruns
Verification, then review, then judgment. Evaluation and attack are optional on the light track and were not run.
