# Observability Coding Standard

- New material failure modes must have a practical detection path.
- Emit structured logs, metrics, traces, events, or audit records at boundaries where they materially improve diagnosis or operations.
- Do not log credentials, secrets, sensitive payloads, or unnecessary personal data.
- Background and asynchronous work must expose failure and retry exhaustion.
- External dependencies should expose latency/error signals when operationally important.
- Instrumentation names and dimensions should remain stable enough for dashboards and alerts.

## Standard dashboard baseline (infrastructure-as-code)

`observability.standard_dashboard` in `.ai/maturity.yml` gates level 5 whenever a repository provisions infrastructure as code (Terraform, OpenTofu, Pulumi, CloudFormation, or equivalent). The bar is APM parity: what Datadog or New Relic gives you out of the box just by attaching an agent, reproduced as a dashboard-as-code resource that lives and is reviewed alongside the infrastructure it observes.

For every provisioned resource, cover:

- **Golden signals** — latency (p50/p95/p99), traffic/throughput, error rate, saturation (CPU, memory, disk, connection/thread pool).
- **RED**, for request-serving components (API, web server, load balancer) — Rate, Errors, Duration.
- **USE**, for backing resources (compute, queue, database, cache) — Utilization, Saturation, Errors.

What that maps to in `.ai/maturity.yml`'s capability set, required per resource type actually provisioned (`capability_guidance.observability.infrastructure_as_code`):

| Provisioned resource | Required capabilities |
| --- | --- |
| Compute / request-serving | `observability.error_rate_signal`, `observability.latency_signal` |
| Queue / async worker | `observability.job_failure_signal`, `observability.backlog_signal` |
| Database | `observability.database_health_signal` |
| External integration | `observability.integration_failure_signal` |

Requirements for the dashboard itself:

- Declared in code (a CloudWatch Dashboard resource, Datadog `dashboard_json`, a provisioned Grafana dashboard, a New Relic dashboard-as-code definition, or equivalent) — never a manually clicked-together dashboard with no source of truth.
- One dashboard per logical service/component group is sufficient; it does not need to be one dashboard per resource.
- Every panel representing a production-impacting resource needs a baseline alarm on error rate, latency/duration, or saturation, wired to `observability.alerting`.

This is separate from `observability.operational_visibility`, which can be satisfied by an in-app operational surface (an admin page showing job/tenant/system state) with no dashboard-as-code requirement. `observability.standard_dashboard` is stricter and IaC-specific: it cannot be satisfied by an in-app page, and it is not exempt the way `operational_visibility` can be — see `.ai/maturity.yml`'s `assessment_rules`.
