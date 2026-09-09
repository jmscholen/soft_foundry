# Change Intake

## User intent
When a `soft-foundry` command or the lifecycle workflow fails, and the likely cause is Soft Foundry itself rather than the maintainer's repository or work, the tool should tell the maintainer how to contribute a fix upstream: fork the Soft Foundry repository and open a pull request (or issue) describing the potential cause. The maintainer's exact words: "should the cli fail or workflow fail, prompt the user to fork the repo and push a PR for the potential cause of the issue because of them cli or soft-foundry commands."

## Desired outcome
- Every failure surfaced by the CLI carries a classification: **target-side** (the maintainer's repository, environment, or incomplete lifecycle work), **provider-side** (a model provider refused or failed), or **soft-foundry-side** (a defect in the CLI, an inconsistent packaged control plane, a contradictory skill contract, or a gate that cannot be satisfied as written).
- A soft-foundry-side failure ends with guidance: the upstream repository URL, a suggested fork-and-branch sequence, and a diagnostic the maintainer can paste into a pull request or issue. The diagnostic includes the command, Soft Foundry version, Ruby version, the error, the suspected component or file, and the classification reasoning.
- A `soft-foundry report` command writes the same diagnostic to a local file under `.soft-foundry/reports/` and prints the `gh` commands that would fork the repository and open the pull request or issue. When `gh` is installed and the maintainer explicitly confirms, the command may run them.
- Workflow failures are covered as well as CLI crashes: a `check` error on a freshly installed control plane is soft-foundry-side; a `gate` failure on a change's own incomplete work is target-side and gets no upstream prompt.

## Constraints
- Nothing is sent anywhere automatically. Reporting is opt-in and each network action is confirmed by the maintainer; this falls under the human-boundary policy for outward-facing actions.
- Diagnostics never include credentials, environment variable values, file contents outside `.ai/`, or the maintainer's application code. Paths are repository-relative.
- Classification must be conservative: when unsure, classify as target-side and do not prompt, so maintainers are not sent upstream with their own bugs.
- Works offline; `gh` is optional.
- Follows the exit-code scheme established by the `init-command` specification, where soft-foundry-side failures exit `4`.

## Non-goals
- Automatic bug fixing or automatic pull-request creation without confirmation.
- Telemetry, crash analytics, or any background transmission.
- Classifying failures inside the maintainer's application under test; those belong to verification, evaluation, and attack evidence.

## Task classification
feature, application surface. Cross-cutting error handling in the CLI plus one new command.

## Initial risk
low. The change adds messaging and a local report file. The only sensitive behavior is the optional `gh` invocation, which is gated behind explicit confirmation and covered by the human-boundary policy.
