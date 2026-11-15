# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Name the attacker | `.ai/skills/adversarial-testing/SKILL.md` | REV-001, REV-002, REV-003 and the maintainer's decision of 2026-11-14 | "The attacker is an outside party who reaches the change through what it exposes: requests, parameters, uploads, jobs, webhooks, command arguments. Attack the code the change added or modified for injection, cross-site scripting, broken authorization, identifier substitution, mass assignment, path traversal, server-side request forgery, data exposure and resource exhaustion. A party with write access to the repository editing the change record, the control plane or git history is out of scope; note it for the guard follow-up and do not record it as an attack result." |
| Grade with the same threat model | `.ai/skills/review/SKILL.md` | REV-001 graded blocking | "Grade a finding against the attack threat model. A finding that needs write access to the repository is never blocking or major; record it as a follow-up." |
| State the purpose | `.ai/README.md`, `README.md` | Maintainer's restatement of 2026-11-14 | "Soft Foundry is an autonomous software factory. An agent builds a feature in an application by passing through gated phases. What each gate checks is locked once a person approves it. Verification, evaluation and attack look at the feature from the outside: what a legitimate user expects and what a bad actor would try through it." |
| Light track for the tool's own changes | `.ai/workflow.yml` (`tracks:`) | Elapsed time of this change | A track whose required phases are intake, specify, implement, verify, review and judge. Evaluation, attack and threat modeling are not required on it. |
| Application-type paths | `.ai/repository.yml`, evaluation and adversarial-testing skills | Maintainer's decision of 2026-11-14 | The repository profile declares an application type (web app, API service, CLI or library). Each type names the default surfaces and threats evaluation and attack cover. |
