# Security Coding Standard

- Apply least privilege to users, services, credentials, IAM, network access, and filesystem access.
- Authenticate identities and authorize actions independently.
- Never trust client-supplied ownership, tenant, role, account, or resource identifiers without server-side authorization.
- Protect against injection, XSS, CSRF, SSRF, path traversal, insecure deserialization, unsafe redirects, and resource exhaustion as applicable.
- Secrets must never be committed, logged, embedded in generated artifacts, or exposed through client-visible configuration.
- Cryptographic behavior must use maintained platform/library primitives rather than custom cryptography.
- Security controls may not be disabled for convenience without an explicit approved exception.
