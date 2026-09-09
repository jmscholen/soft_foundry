# Adversarial Testing

Try to make the implementation violate its intent. Use real UI, HTTP/API, job, file-processing, data, and infrastructure surfaces as applicable. Attempt unauthorized state changes, identifier substitution, malformed/large input, replay, concurrency, injection, XSS, SSRF, path traversal, resource exhaustion, and dependency failures. Report findings; do not repair them.

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
