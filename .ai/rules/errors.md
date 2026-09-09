# Error Handling Standard

- Failures must be classified, surfaced at the appropriate boundary, and observable.
- Do not silently discard exceptions or failed external operations.
- Retry only errors that are plausibly transient, with bounded retry behavior and idempotency safeguards.
- Preserve useful diagnostic context without exposing secrets or sensitive data.
- User-facing errors should be actionable without leaking implementation details.
- A fallback must not convert an integrity or security failure into apparent success.
