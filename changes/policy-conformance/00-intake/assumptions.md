# Assumptions

## Explicit assumptions
- "The application it is a foundry on" means the governed repository's product: the thing whose users read a privacy policy. Soft Foundry's own tool-level data handling is out of scope here and named as a non-goal.
- The flag is named `surfaces.policy`, not `surfaces.personal_data` as first sketched in conversation, because the standard covers security-policy promises (encryption, disclosure timelines) that are not personal data. Recorded in `05-implementation/decisions.md`.
- The accessibility precedent (2026-09-13) is the shape: a rule file, a surface flag `change new` can set from the repository profile, a required review file, advisories that report and never block, a level-5 maturity capability, a `check` warning. The maintainer's standing instruction "report on the issues, don't make them a gate to advancing" applies unchanged.
- "Published policy document recorded" means status PASS with evidence in `.ai/repository.yml`; MISSING, UNKNOWN, and NOT_APPLICABLE do not set the flag, because there is no document to check against, but a true flag in such a repository is advised so the gap is visible.
- A human decision is recorded in `metadata.yml` rather than in a phase handoff because it is not evidence a phase produced; it is a fact about the change that any phase may need to read, and `metadata.yml` is already where `status: awaiting_human` lives per `.ai/schemas.md`.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, and the review phase is run for it because the change is about review. That choice is recorded here rather than silently taken.

## Ambiguities resolved
- Whether the scan may record MISSING for a policy document: no. The maturity model's own rule is that absence must be established, and an application may publish its policy on a marketing site the repository never sees. The scan records UNKNOWN; discovery records MISSING.
- Whether an owed policy text change should block the gate: no, per the maintainer's rule. It is advised, with the exact words `status: awaiting_human`, and the advisory changes wording once the status is set so the reader can tell "not yet parked" from "parked, waiting".
- Whether evaluation owes policy evidence the way it owes accessibility observations: no. Policy conformance is a reading of code against a document, which is review's job; evaluation exercises behaviour. The threat model owes a trust boundary per new recipient instead.
- Whether to add a line to `.ai/policies/human-boundaries.yml`: yes. "Legal commitments" already covered it, but the whole point of this change is that nothing routed a policy text change there; naming it removes the ambiguity. Policies are protected from every *skill's* write set; this is a maintainer change through its own record.
- This repository's own `policies:` block: privacy and terms NOT_APPLICABLE with rationale (a library gem, no users' data, no service), security MISSING (a public gem with no `SECURITY.md` or disclosure route). The MISSING is deliberate and is this change's first real finding about the repository it runs in.

## Ambiguities that block safe progress
None.
