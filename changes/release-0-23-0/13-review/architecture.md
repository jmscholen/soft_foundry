# Architecture Review

## Scope reviewed

The same HEAD and diff as the functional review, read against `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, and `.ai/rules/dependencies.md`. Repository profile: plain Ruby gem, no application framework, no database. `infra/` holds a README and no resources.

## Findings

None.

`SoftFoundry::VERSION` remains the single gem version. `soft_foundry.gemspec` reads it with `require_relative "lib/soft_foundry/version"` and assigns `spec.version`. The CLI prints that constant for `version`, `--version`, and `-v`, and interpolates it in the help header. The updater defaults `current:` to it and sends it in the User-Agent. No second gem version was introduced. `Manifest::VERSION` and `Snapshot::VERSION` stay file-format versions.

The decision to ship `0.23.0` rather than `0.22.1` is recorded in `05-implementation/decisions.md`: gate-hardening added commands and checks. That matches the intake assumption. No new module, dependency, or boundary.

## Conformance

Conforms to `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, and `.ai/rules/dependencies.md`. No dependency was added. No deviation from the waived plan is recorded, and the diff does not contain one.
