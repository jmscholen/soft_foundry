# Privacy and Security Policy Conformance Standard

Applies to any change that alters what the governed application collects, uses, shares, retains, or protects, or what it promises about those things in its own published privacy policy, security policy, terms of service, or equivalent commitments (a data processing agreement, a subprocessor list, a trust page, a vulnerability disclosure policy). Implementation loads this file whenever `surfaces.policy` is `true` in the change's `metadata.yml`; review cites it in `13-review/policy-conformance.md`. Findings against this standard are reported as go-live advisories, never as a blocker to lifecycle advancement: `soft-foundry gate`, `change status`, `ci`, and `change close` print what still needs attention before the change goes live, and the human deciding to ship owns that call.

The engineering rules in `security.md` say how code must be written. This standard says something different: whatever the application has told its users and customers in writing must still be true after the change ships.

## What the application has promised

- Repository discovery records the application's published policy documents in `.ai/repository.yml` under `policies:` (`privacy`, `security`, `terms`), each with its path or URL and a status. `PASS` means the document was found and is the one users see; `MISSING` means the application publishes none and that absence is established; `UNKNOWN` means discovery could not tell; `NOT_APPLICABLE` requires a rationale (a library with no users' data, for instance).
- `MISSING` is a legitimate answer and a visible one. An application that processes personal data and publishes no privacy policy has a go-live gap of its own, and review says so rather than declaring conformance to a document that does not exist.
- A repository may name a stricter or more specific regime in its own rules (GDPR, CCPA/CPRA, HIPAA, PCI DSS, SOC 2 commitments, a customer contract); the stricter requirement wins.

## Changes that engage this standard

Set `surfaces.policy: true` when the change does any of the following. `change new` sets it automatically when the repository profile records a published policy document; the author turns it off with a reason when the change touches none of this.

- Collects something new from or about a person: a form field, a log line, an analytics or telemetry event, a cookie or local storage key, device, location, or biometric data, content a person writes.
- Adds a recipient: an SDK, vendor, subprocessor, third-party API, model provider, or hosting region that will receive data the policy covers.
- Changes retention or deletion: backups, archives, time-to-live, what account deletion actually removes, what is kept after a person leaves.
- Changes purpose: data collected for one stated purpose used for another (training or evaluating a model, marketing, profiling, analytics).
- Changes a security commitment the policy names: authentication factors, encryption at rest or in transit, session handling, access controls, breach notification, vulnerability disclosure timelines.
- Changes a consent or rights mechanism: opt-in or opt-out, export, deletion, "do not sell or share", age gating.

## Rules

- Every data element the change introduces is classified (`none`, `personal`, `sensitive`, `credential`) and its purpose, recipients, and retention are stated in the specification before implementation begins.
- Nothing the change ships contradicts a published clause. Conformance is judged against the document users can actually see, not against an internal draft.
- Where a clause would have to change for the code to be honest, the review lists that policy text change as owed. Publishing a change to a privacy policy, security policy, or terms is a legal commitment under `.ai/policies/human-boundaries.yml`: the change is parked with `status: awaiting_human` in `metadata.yml` until a person decides, and the decision is recorded under `human_decisions` there. The policy is published before or with the code, never after.
- Collect the minimum the stated purpose needs, and default to not collecting. A field that is merely convenient to have is a finding.
- Data the policy covers goes only to recipients the policy names. Model providers used by the engineering lifecycle receive repository content, not end-user data; evaluation and adversarial testing use synthetic data (see the adversarial-testing skill and the human-boundary policy).
- Logs, error reports, and observability payloads are part of the data flow: what they capture is subject to the same clauses (see also `observability.md`).
- A security promise in the policy (encryption, multi-factor authentication, disclosure within a stated period) is checked here as a promise; how it is implemented is checked against `security.md`.

## Evidence the lifecycle expects

- **Discovery** records or refreshes the `policies:` block in `.ai/repository.yml` and names the documents in `01-discovery/repository-context.md` under "Published policies".
- **Specification** records at least one requirement with `category: policy` stating what the change collects, shares, retains, or promises differently and which document and clause covers it, or states why nothing the policies cover changes.
- **Threat model** shows every new recipient of covered data as a trust boundary.
- **Review** fills `13-review/policy-conformance.md` with the documents checked, findings citing a clause or a rule above, the policy text changes owed (or "None"), and a conformance statement other than N/A.
