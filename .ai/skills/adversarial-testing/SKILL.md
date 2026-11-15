# Adversarial Testing

Try to make the implementation violate its intent. Use real UI, HTTP/API, job, file-processing, data, and infrastructure surfaces as applicable. Attempt unauthorized state changes, identifier substitution, malformed/large input, replay, concurrency, injection, XSS, SSRF, path traversal, resource exhaustion, and dependency failures. Report findings; do not repair them.

## The attacker

The attacker is an outside party who reaches the change through what it exposes: requests, parameters, uploads, jobs, webhooks, command arguments. That covers a visitor who is not signed in, a signed-in user acting beyond their permissions, and another system calling the feature.

Attack the code the change added or modified. Try each class that applies to it:

1. Injection (SQL, command, template).
2. Cross-site scripting.
3. Broken authorization.
4. Identifier substitution (reaching another party's record by changing an identifier).
5. Mass assignment.
6. Path traversal.
7. Server-side request forgery.
8. Data exposure.
9. Resource exhaustion.

Out of scope: a party with write access to the repository editing the change record, the control plane or git history. That is handled by the runtime guard and the specification lock, not by this phase. They do not close it completely: `rules`, `risk` and `track` in a record's `metadata.yml` can still be edited by a party with write access, and that gap is tracked as guard work. If you notice such a weakness, note it as a follow-up in the handoff `notes`. Do not record it as an attack result and do not give it a severity.

## Authorization and scope

Adversarial testing is authorized engineering validation, not unrestricted offensive activity. Before execution, the harness must establish the target, environment, ownership/authorization, permitted surfaces, prohibited surfaces, data constraints, network constraints, and whether destructive actions are allowed.

Prefer ephemeral, local, test, or staging environments with synthetic data. Production testing, destructive testing, third-party targets, real customer data, credential-sensitive actions, or expansion beyond the declared target require explicit authorization under the human-boundary policy.

The skill must remain inside the supplied scope even when a technically reachable system exists outside it. Absence of evidence that a target is authorized is a reason to stop or escalate, not permission to proceed.

## Model-provider behavior

A model provider may decline an adversarial action. Treat refusals as structured outcomes rather than instructions to evade provider safeguards.

- If the refusal indicates missing authorization, unsafe scope, a prohibited target, destructive behavior, or another legitimate safety boundary, mark the attack blocked and escalate as appropriate. Do not route the same request to another provider merely to bypass the refusal.
- If the failure is a non-safety capability limitation such as unavailable browser tooling, unsupported tool use, context limits, transient provider failure, or an otherwise authorized benign test the selected runtime cannot execute, the harness may select another model/runtime that satisfies the `adversarial_high` profile.
- Provider fallback must preserve the exact authorization envelope and may never broaden target scope.

The harness owns authorization and scope. The model is responsible for adversarial reasoning and execution only within that envelope.

## Purpose of ATTACK

ATTACK is broader than penetration testing. It attempts to disprove implementation assumptions across security, authorization, reliability, concurrency, integrity, resource abuse, malformed inputs, dependency failures, retry behavior, and operational boundaries.

EVALUATION asks whether legitimate behavior succeeds. ATTACK asks whether illegitimate behavior can succeed or intended behavior can be broken.


This phase prefers a fresh session: `soft-foundry phase run attack` starts one with only this skill in its prompt and records `executed_by` in the handoff; an attack completed by the session that implemented the change is advised on every gate run.

On a record under the convergence rules, direct the attack at what the change modified and at its must acceptance criteria. A weakness in code the change did not modify is still worth reporting: mark the finding `outside_change: true`, name the `paths` it concerns and a `follow_up`, and it is carried as a follow-up instead of blocking this change (the gate's `outside-change findings` check refuses the mark on a path this change modified).

Run `soft-foundry change size --phase attack` and attack what it names; record the size with the evidence. `touched_doors_plus_smoke` means the doors the change touches plus a sign-in and app-wide smoke test; `full_route_sweep` means every route.

Payloads that contain invisible, zero-width, bidirectional or control characters are written into evidence as visible escapes (for example `<U+200B>` for a zero-width space or `<U+202E>` for a right-to-left override) or are built inside a script with an escape such as `\u{200B}`, never pasted raw. A raw hidden character in evidence fails the `content clean` gate. Record in the manifest or notes that a payload is shown escaped.
