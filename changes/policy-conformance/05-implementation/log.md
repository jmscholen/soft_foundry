# Implementation Log

## Changes made
- `.ai/rules/policy-conformance.md` (new): the standard. What the application has promised and where discovery records it; the kinds of change that engage the standard; the rules (classification, no contradiction of a published clause, owed policy text is a legal commitment, minimisation, recipients, logs, security promises); the evidence each phase owes.
- `.ai/skills/review/template/policy-conformance.md` (new) and `completion.yml`, `skill.yml`, `SKILL.md`, `template/consolidated.md`: the review requires `policy-conformance.md` (documents checked, findings, policy text changes required, conformance) and consolidates it.
- `.ai/skills/specification/SKILL.md`, `template/requirements.yml` (`policy` category), `template/specification.md` (a conformance section); `.ai/skills/repository-discovery/SKILL.md` and `template/repository-context.md` ("Published policies"); `.ai/skills/threat-modeling/SKILL.md` (a new recipient is a trust boundary).
- `.ai/templates/repository.yml`: a `policies:` block (privacy, security, terms; UNKNOWN until assessed). `.ai/repository.yml`: this repository's own block (privacy and terms NOT_APPLICABLE with rationale; security MISSING, no `SECURITY.md`) and `policy_conformance.standard_in_force: PASS`.
- `.ai/templates/change/metadata.yml`: `surfaces.policy` with its comment; `human_decisions: []` with a commented example.
- `.ai/policies/human-boundaries.yml`: publishing or changing the application's privacy policy, security policy, or terms is named explicitly under `require_human_approval`.
- `.ai/maturity.yml`: `policy_conformance.standard_in_force` required at level 5, with an assessment rule.
- `lib/soft_foundry/advisory.rb`: policy notices (missing standard; published documents but flag false; flag true with no document to check against; specification without a `category: policy` requirement or skipped; review pending, skipped, missing, TBD, or N/A; policy text changes owed with no human decision, worded differently before and after `status: awaiting_human`). The accessibility and policy requirement checks share one method. `Advisory.ui_frameworks` and `Advisory.policy_documents` are class methods so `change new` can use them. The review-skipped notice now names policy among what went unchecked.
- `lib/soft_foundry/change_record.rb`: `declare_surfaces!` sets `accessibility` and `policy` by one-line text edits when the profile records a user-facing framework or a published policy document, preserving the template's comments.
- `lib/soft_foundry/maturity_scan.rb`: `policy_documents` and `policies` look for privacy, security (including `.well-known/security.txt`), and terms documents by case-insensitive basename in a fixed list of directories; `run!` writes the `policies:` block; `policy_conformance.standard_in_force` scored from file presence (PASS / UNKNOWN).
- `lib/soft_foundry/check.rb`: warning when the standard is absent from an installed plane.
- `.ai/schemas.md`, `.ai/rules/README.md`, `AGENTS.md`, `README.md`: the flag, the block, `human_decisions`, the advisory semantics.
- Tests: `test/advisory_test.rb` (`PolicyAdvisoryTest`: every notice, the `change new` flag with comments preserved, the human-decision lifecycle, gate exit code; `check` warning), `test/maturity_scan_test.rb` (document detection, UNKNOWN for absence, the capability, the written block), `test/maturity_scoring_test.rb` (level 5 blocked without the standard).
- Version bumped to 0.8.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- The first honest output of this standard was about the repository it runs in: Soft Foundry publishes no security policy or vulnerability disclosure route. Recording MISSING there, rather than NOT_APPLICABLE, is the behaviour the standard asks of every governed repository, so the tool's own profile has to model it.
- "Absence established" and "not found" have to stay different statuses all the way down: the scan finding nothing must not become MISSING, or every repository whose policy lives on a marketing site would be told it has none.
- A human-boundary decision needs a durable home before an advisory can say "resolved". Without `human_decisions`, the only options were to nag forever or to trust that `awaiting_human` had been cleared for the right reason.

## Challenges
None substantive. One archived evidence file from a prior change (`changes/init-command/06-verification/previous/6df4d15e73d8/tests.yml`) does not parse as YAML; it is pre-existing history under `previous/`, untouched, and not read by the gate.
