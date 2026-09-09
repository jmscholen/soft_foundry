# Architecture Standard

- Respect existing bounded contexts, layering, ownership boundaries, and dependency direction.
- Domain behavior should not depend directly on delivery mechanisms such as HTTP, CLI, queues, or UI unless that coupling is intentional.
- Infrastructure and external services must be isolated behind clear interfaces when doing so improves testability or portability.
- Avoid cyclic dependencies and hidden global coupling.
- Prefer composition over inheritance for application behavior.
- New abstractions must solve a demonstrated problem; do not create framework layers in anticipation of future needs.
- Cross-cutting concerns such as authorization, auditing, retries, logging, metrics, and feature flags must have explicit ownership.
- Architectural decisions with meaningful long-term consequences must be recorded in the change artifacts.
