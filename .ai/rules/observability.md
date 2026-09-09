# Observability Coding Standard

- New material failure modes must have a practical detection path.
- Emit structured logs, metrics, traces, events, or audit records at boundaries where they materially improve diagnosis or operations.
- Do not log credentials, secrets, sensitive payloads, or unnecessary personal data.
- Background and asynchronous work must expose failure and retry exhaustion.
- External dependencies should expose latency/error signals when operationally important.
- Instrumentation names and dimensions should remain stable enough for dashboards and alerts.
