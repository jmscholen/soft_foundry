# Implementation Log

## Commits (in order)
1. `7abfe3f` — Require a standard APM-equivalent dashboard when IaC is present. Adds `observability.standard_dashboard` to level 5's `requires` in `.ai/maturity.yml`, a new `capability_guidance.observability.infrastructure_as_code` block mapping provisioned resource type to required signal capabilities, two new `assessment_rules` entries (the `NOT_APPLICABLE`-gating rule and the clarification that it doesn't share `operational_visibility`'s dashboard exemption), and the normative "Standard dashboard baseline" section in `.ai/rules/observability.md` (Golden Signals / RED / USE, dashboard-as-code requirement, applicability rules).
2. `78ee8b2` — Close `maturity-report`'s change record (`status: ready_for_pr` → `closed`). Unrelated cleanup surfaced while trying to land this change: that record's PR (#6) had already merged but was never closed, so its commit-bound verification/evaluation evidence went stale the moment any `APP`-path file changed, which blocked `soft-foundry ci`'s pre-commit hook. Fixed using the same closure pattern as `self-update` (`3d49a67`).
3. `a91b43a` — Bump `lib/soft_foundry/version.rb` to `0.4.0`, matching this repo's existing minor-bump-per-merged-change pattern (`0.1.0` → `0.2.0` → `0.3.0`).
4. `305e035` — Add `test/maturity_scoring_test.rb` regression coverage for the new capability's three states (`MISSING` blocks level 5, `NOT_APPLICABLE` still reaches it, `PASS` reaches it) against this repo's own real `.ai/maturity.yml` via `ControlPlane#score_maturity`.

## Sequencing note
Commits 1–3 were originally made directly, and one (`cfe2c8d`, since rewritten) accidentally bundled the version bump with the metadata fix due to a leftover `git add` staging the version file across a failed pre-commit-hook attempt. Caught and corrected before push: `git reset` back one commit and re-committed the two changes separately as `78ee8b2` and `a91b43a`. No content was lost or altered — only history was reordered, and only while entirely local/unpushed.

## Why a real code change (test) for a documentation/policy change
`observability.standard_dashboard`'s scoring semantics are executed by real code (`ControlPlane#score_maturity` in `lib/soft_foundry/control_plane.rb`), not just interpreted narratively by an assessing agent. Adding regression coverage was judged worth the extra scope over a pure YAML/Markdown-only change, since this repo's own `verification.automated_tests` capability expects exactly that discipline of itself.
