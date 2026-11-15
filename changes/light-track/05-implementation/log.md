# Implementation Log

## Changes made
- RED `a53ec00`: `test/light_track_test.rb`, 16 tests. 15 failed or errored at that commit; the gated-track control passed.
- GREEN (the commit that follows this log):
  - `.ai/workflow.yml`: a `light` track whose optional phases are discover, threat_model, plan, evaluate, attack and learn (REQ-001, REQ-002). No gate code was needed; `ChangeRecord#skippable?` already honours a track's optional list.
  - `lib/soft_foundry/process_rules.rb`: `normalize_path` (REQ-005); `text_only_path?` (REQ-007); `reopened_rounds` ignores a reopen entry whose remediation was not sealed, and the cap refusal says "has run N remediation rounds" (REQ-006).
  - `lib/soft_foundry/gate.rb`: the outside-change check normalizes paths and refuses absolute paths, paths leaving the repository and globs (REQ-005); the cap check message no longer says "sealed" (REQ-006).
  - `lib/soft_foundry/phase_reopen.rb`: a reopen entry records `sealed` for the remediation it resets (REQ-006).
  - `lib/soft_foundry/sizing.rb`: with no plan commit the diff base is the first recorded phase; a verify diff of documentation and control-plane Markdown gets the smaller size (REQ-007).
  - `lib/soft_foundry/change_record.rb`, `lib/soft_foundry/cli.rb`: `skip_reason`, printed by `change status` for a pending phase that may stay pending; help text names the light track (REQ-009, REQ-012).
  - `.ai/templates/change/metadata.yml`, `.ai/README.md`, `README.md`, `docs/user/light-track.md`, `docs/user/README.md`: the light track documented (REQ-009). The index also gains the missing row for `converging-changes.md`.
  - `.ai/skills/review/SKILL.md`, `.ai/skills/adversarial-testing/SKILL.md`: the two wording fixes (REQ-008).
  - `test/lifecycle_tracks_test.rb`: the track-list assertion now includes `light` (DEV-003).

Full suite before the commit, provider keys and SOFT_FOUNDRY_PHASE unset: 951 runs, 6981 assertions, 1 failure (the track-list assertion, DEV-003). After the one-line correction the two track test files pass (41 runs, 0 failures); the full suite was not rerun by this session and is verification's to run.

Files under `.ai/` and `metadata.yml` were written under the maintainer's local warn override.

## Decisions
See decisions.md.

## Deviations from plan
See deviations.md: DEV-001, DEV-002, DEV-003.

## Challenges
- A shell command carrying Ruby with apostrophes inside single quotes failed to parse; the patch was run from a script file instead.
