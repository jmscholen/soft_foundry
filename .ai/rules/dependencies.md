# Dependency Standard

- Prefer existing platform/library capabilities before adding a new dependency.
- New dependencies require a concrete need, maintained upstream, compatible license, acceptable security posture, and bounded operational cost.
- Pin or constrain versions according to ecosystem norms and commit lockfiles where the ecosystem expects them.
- Avoid introducing overlapping libraries that solve the same concern without justification.
- Remove dependencies that become unused as part of the change.
