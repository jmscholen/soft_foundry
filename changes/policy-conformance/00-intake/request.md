# Change Intake

## User intent
The maintainer asked whether a privacy and security policy review would be of benefit, clarified that they meant the privacy and security policy *of the application Soft Foundry is a foundry on* (not Soft Foundry's own), and, on hearing the gap and the recommended shape, said: "Add it as recommended."

The assessment that preceded it: the lifecycle checks every change against engineering security rules (`.ai/rules/security.md`, threat modeling, the attack phase, the review's `security.md`) but never against what the governed application has promised its users in its own published privacy policy, security policy, or terms. Discovery has no slot for those documents, the repository profile does not record whether they exist, specification does not require a statement of what a change collects, shares, retains, or promises differently, review has no file for it, and although `.ai/policies/human-boundaries.yml` already names legal commitments as requiring human approval, nothing routes a policy text change there.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-POL-001.** A named standard exists in the control plane: `.ai/rules/policy-conformance.md`. It says what documents count (privacy policy, security policy, terms, equivalents), which kinds of change engage it (new collection, new recipient, retention, purpose, security commitment, consent or rights mechanism), the rules (classify every new data element; nothing shipped contradicts a published clause; an owed policy text change is a legal commitment; minimisation; recipients limited to those the policy names; logs are part of the data flow), and the evidence each phase owes. Discovery, specification, threat-modeling, and review skills reference it.
- **REQ-POL-002.** Repository discovery records the application's published policy documents under `policies:` in `.ai/repository.yml` (`privacy`, `security`, `terms`), each with a status of PASS, MISSING, UNKNOWN, or NOT_APPLICABLE and evidence or rationale. MISSING is a legitimate, visible answer. The template profile carries the block; the deterministic scan populates it from file presence (PASS with paths, otherwise UNKNOWN), looking where applications publish such documents including `.well-known/security.txt`.
- **REQ-POL-003.** `surfaces.policy` in a change's `metadata.yml` is read by code. `change new` sets it to `true` when the repository profile records a published policy document as PASS. With the flag true, the tool reports a specification without a `category: policy` requirement (or a skipped specification), a policy-conformance review that is pending, skipped, missing, still holding template placeholders, or N/A, and a repository profile that records no published document to check against. With the flag false in a repository whose profile records a published document, the tool asks the author to confirm.
- **REQ-POL-004.** The review skill requires `13-review/policy-conformance.md`: documents checked, findings citing a policy clause or a rule, policy text changes required (or None), and a conformance statement. `consolidated.md` gains a matching section.
- **REQ-POL-005 (human boundary).** A review that lists policy text changes owed has found a legal commitment. `.ai/policies/human-boundaries.yml` names publishing or changing those documents explicitly. `metadata.yml` gains `human_decisions`, where a person's decision (boundary, subject, decided_by, decided_at, decision) is recorded. Until such an entry exists, the advisory says the change is parked (`status: awaiting_human`) awaiting a person, and says so whether or not the status has been set yet.
- **REQ-POL-006 (the maintainer's constraint, carried over).** All of the above are advisories: printed after the gate results by `gate`, `change status`, `ci`, and one last time by `change close`, each line starting with `! warn policy:`. They never change an exit code and never block a phase or a close.
- **REQ-POL-007.** The maturity model requires the standard to be in force at level 5 (`policy_conformance.standard_in_force`); the scan scores it from file presence; this repository's profile records it PASS, and records its own published policies honestly (privacy and terms NOT_APPLICABLE for a library gem, security MISSING because there is no `SECURITY.md`).
- **REQ-POL-008.** `soft-foundry check` warns (never errors) when an installed control plane lacks the standard. `AGENTS.md`, `.ai/schemas.md`, `.ai/rules/README.md`, and `README.md` document the flag, the `policies:` block, `human_decisions`, and the advisory semantics.

## Constraints
- Advisories must not fail anything: no exit-code change in `gate`, `status`, `ci`, or `close`, and no new gate check outcome of `:fail`.
- Existing change records must keep passing `ci` unchanged; records without `surfaces.policy` or `human_decisions` keys are read as false and empty.
- The `.ai/` directory is packaged and installed into other repositories, so the standard, the template, and the profile block ship with the gem automatically; nothing machine-local is written.
- Comments in `metadata.yml` must survive `change new`'s flag edits.
- The scan must not guess: a document it cannot find is UNKNOWN, not MISSING; only discovery may establish MISSING.

## Non-goals
- Judging the legal adequacy of any policy document; the standard checks that code and promises agree, not that the promises are lawful.
- Auditing Soft Foundry's own data handling as a tool (which provider receives repository content, the ledger's username field); a separate change.
- Static analysis of data flows; the review agent reads the change and the documents.
- Enforcing `awaiting_human` at the gate; it is reported, per the maintainer's standing rule for this family of checks.

## Task classification
Feature: a new rule file, a new review template and completion requirement, a `policies:` block in the repository profile template and this repository's profile, scan detection and a maturity capability, `surfaces.policy` and `human_decisions` in change metadata, policy advisories in the `Advisory` module, a `change new` behavior, a `check` warning, a human-boundary line, documentation, tests.

## Initial risk
low. Output-only behavior plus one text edit to a file `change new` has just written and a read-only directory listing in the scan; no new external interaction, credential, or network access; existing tests and change records continue to pass unchanged.
