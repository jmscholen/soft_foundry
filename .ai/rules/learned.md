# Learned Rules

Instincts promoted from change records by `soft-foundry learn promote`: each
entry names the change that learned it, its confidence when promoted, and the
evidence in that record. Implementation and exploration load this file with
the baseline rules. Edit it only through a change record, the way it was
written.

## commit-the-failing-test-first

- **When:** when starting a feature, fix, or refactor
- **Do:** commit the failing test alone before any implementation, then name that commit as red_commit on the verification check that runs it
- **Confidence:** 0.90 (from change learning-instincts, domain testing; evidence: red-green-evidence REV-020, changes/red-green-evidence/06-verification/tests.yml, changes/learning-instincts/06-verification/tests.yml)

## check-the-commit-landed-before-binding-evidence

- **When:** when about to generate or bind evidence to a commit in a repository with a pre-commit hook
- **Do:** confirm HEAD moved after git commit before generating anything that names the commit
- **Confidence:** 0.85 (from change learning-instincts, domain git; evidence: changes/phase-runner/05-implementation/log.md, changes/phase-runner/05-implementation/deviations.md)

## regenerate-evidence-never-annotate

- **When:** when a transcript or evidence file shows the wrong thing because of a harness or script error
- **Do:** fix the harness and regenerate the evidence in full rather than annotating what the wrong run showed
- **Confidence:** 0.85 (from change learning-instincts, domain verification; evidence: changes/lifecycle-tracks/07-evaluation/results.md, changes/red-green-evidence/07-evaluation/results.md, changes/learning-instincts/07-evaluation/results.md)

## measure-staleness-on-the-record-branch

- **When:** when an open record from another branch reads as stale on a branch stacked on it
- **Do:** do not rebind the earlier record to the later commit; the record's own branch is the measure, and the tool now does this
- **Confidence:** 0.80 (from change learning-instincts, domain governance; evidence: changes/phase-runner/05-implementation/deviations.md, test/stacked_branch_test.rb)

## exempt-closed-evidence-in-policy-not-by-editing-it

- **When:** when a scan flags something in a closed record's commit-bound evidence that is legitimately there
- **Do:** add a narrow allowlist entry with the paths, the kind, a substring, and a reason in policy; never edit the evidence
- **Confidence:** 0.85 (from change control-plane-scan, domain governance; evidence: .ai/policies/content-scan.yml, changes/control-plane-scan/00-intake/assumptions.md)

## sanitize-transcripts-before-they-become-evidence

- **When:** when an evaluation journey deliberately writes an attack, a secret shape, or an invisible character and its output is captured as evidence
- **Do:** have the harness render invisible characters as code points and mask secret shapes before the output reaches the transcript, so the evidence describes the attack without containing it
- **Confidence:** 0.85 (from change control-plane-scan, domain verification; evidence: changes/control-plane-scan/07-evaluation/results.md, control-plane-scan REV-005)

## a-hook-decides-or-refuses-never-raises

- **When:** when writing a hook whose refusal is one exit code and whose other exits the host treats as allow
- **Do:** rescue everything into a refusal; an exception is a fail-open
- **Confidence:** 0.90 (from change factory-readiness, domain security; evidence: ATK-F6, changes/factory-readiness/08-attack/results.md)

## bind-waivers-to-risk-and-never-waive-the-verdict

- **When:** when a lifecycle lets a required phase be waived with a sentence
- **Do:** list per declared risk what may be waived, make review and judgment unwaivable, refuse to close without a judgment, and plant the waived record as a harness eval so the refusal is measured
- **Confidence:** 0.90 (from change factory-readiness, domain governance; evidence: REQ-FR-007, changes/factory-readiness/01-discovery/repository-context.md)

## run-the-lifecycle-in-block-mode-before-trusting-a-warn-mode-control

- **When:** when a guard, lint, or hook has been running in a mode that reports but allows
- **Do:** switch it to refuse and run one full lifecycle under it before calling it a control; what it had only been reporting is the first finding
- **Confidence:** 0.90 (from change factory-readiness, domain security; evidence: REM-001, changes/factory-readiness/06-verification/results.md)

## check-the-request-against-the-users-real-situation

- **When:** when a feature is meant to show what is happening on the user's machine or in their data
- **Do:** before calling it done, run it against the real situation in front of you and ask whether what the user would expect to see is there; a staged evaluation only proves the thing you built
- **Confidence:** 0.90 (from change ui-processes, domain evaluation; evidence: changes/ui-processes/09-remediation/summary.md, REV-026)

## report-fields-never-the-command-line

- **When:** when showing or logging information about another process
- **Do:** report named fields that pass validation and never the command line, which can hold a prompt, a token, or anything the process chose
- **Confidence:** 0.90 (from change ui-processes, domain security; evidence: ATTACK-001, changes/ui-processes/03-threat-model/mitigations.md)

## open-the-page-before-trusting-its-tests

- **When:** when a change serves a page to a browser
- **Do:** load it in a real browser before recording verification; a request test only proves the server does what the test author assumed a browser sends
- **Confidence:** 0.90 (from change ui-server, domain testing; evidence: changes/ui-server/05-implementation/deviations.md, changes/ui-server/07-evaluation/evidence/browser-observations.log)

## read-the-host-contract-before-writing-an-adapter

- **When:** when asked to make a hook, runner, or installer work for another agent CLI
- **Do:** read that CLI's published contract and its installed help first; the adapter you need may be a parser, not a field rename
- **Confidence:** 0.85 (from change cross-cli-hooks, domain integration; evidence: changes/cross-cli-hooks/00-intake/assumptions.md, changes/cross-cli-hooks/05-implementation/deviations.md)

## a-skill-may-name-what-it-may-read

- **When:** when a skill's shell commands are checked against what it may not write and the skill must run tests or the tool over those paths
- **Do:** treat naming a readable path in a shell command as a read, refuse only what the skill may not read and what is protected, and let the gate's staleness check catch a write
- **Confidence:** 0.85 (from change factory-readiness, domain governance; evidence: REM-001, changes/factory-readiness/09-remediation/summary.md)

## back-a-name-based-check-with-a-state-check

- **When:** when a control decides by recognising path names in free text such as a shell command
- **Do:** do not add another spelling to the parser; record the state the names protect before the call and restore it after, then accept the remaining same-user routes as the sandbox residual
- **Confidence:** 0.85 (from change factory-readiness, domain security; evidence: ATK-F8, changes/factory-readiness/09-remediation/summary.md)

## record-a-baseline-only-in-the-call-that-consumes-it

- **When:** when a pre-call baseline and a post-call check protect a piece of state and only some tool calls have the post-call half
- **Do:** record the baseline only for the calls that have the check, and let the person's own commands clear it; otherwise the check reverts the person's edit between calls
- **Confidence:** 0.85 (from change factory-readiness, domain design; evidence: EVAL-F7, changes/factory-readiness/09-remediation/summary.md)

## observe-results-not-commands

- **When:** when enforcing what an untrusted agent step may change
- **Do:** snapshot what you can see before and after the step and compare, rather than parsing the step's commands for paths
- **Confidence:** 0.85 (from change panel-phases, domain security; evidence: REV-SEC-005, changes/panel-phases/09-remediation/summary.md)

## inject-the-failure-to-prove-fail-closed

- **When:** when claiming a crash or race leaves the record safe
- **Do:** drive a real kill at each step or run the concurrent pair and capture the output, rather than arguing from reading the code
- **Confidence:** 0.85 (from change phase-lifecycle-controls, domain verification; evidence: 08-attack, ATK-001)

## one-definition-of-a-state-across-surfaces

- **When:** when the CLI and a browser page both decide whether an item is open or done
- **Do:** compute the state once on the server and send the result, instead of re-implementing the test in each language
- **Confidence:** 0.85 (from change phase-lifecycle-controls, domain architecture; evidence: REV-002, REV-009)

## order-renames-so-a-crash-fails-closed

- **When:** when a command must update several files and cannot make them atomic
- **Do:** rename the evidence files first and the record of intent last, so a crash leaves a state that later checks refuse rather than a history of work not done
- **Confidence:** 0.85 (from change phase-lifecycle-controls, domain architecture; evidence: REV-001, 09-remediation)

## no-rename-collapse-in-staleness-diffs

- **When:** when a changed-path list from git decides staleness, check size, or an access-control match
- **Do:** list the diff with --no-renames so both sides of a rename appear, and add a rename test
- **Confidence:** 0.85 (from change scoped-verification, domain security; evidence: ATTACK-013)

## verify-specification-yaml-parses-before-lock

- **When:** when finishing a YAML artifact that tooling will load, especially a locked specification
- **Do:** load it with YAML.safe_load and quote any statement containing a colon followed by a space
- **Confidence:** 0.85 (from change scoped-verification, domain testing; evidence: REC-001)

## run-built-command-lines-live-once

- **When:** when code builds the argument list for an external CLI such as claude, codex, or grok
- **Do:** run the exact built command once against the installed program before review; an array-equality test does not prove the program accepts it
- **Confidence:** 0.85 (from change session-ledger, domain testing; evidence: REM-001, changes/session-ledger/09-remediation/summary.md)

## carry-deferred-findings-into-the-next-intake-by-id

- **When:** when a review defers a finding to a later change
- **Do:** name the finding's ID in that later change's intake as a requirement, and close it with a test there
- **Confidence:** 0.85 (from change ui-explainer-timeline, domain review; evidence: changes/ui-explainer-timeline/00-intake/request.md)

## every-reference-is-a-link-with-its-source

- **When:** when a page names a thing that has its own page or file
- **Do:** make the name a link, and let hovering or focusing it say what it is and which file it lives in
- **Confidence:** 0.85 (from change ui-links, domain design; evidence: changes/ui-links/00-intake/request.md)

## a-wider-view-needs-a-wider-frame

- **When:** when adding a view whose scope is wider or narrower than the page or tool it is added to
- **Do:** say on every page what it is scoped to, and change the navigation to match the scopes, before adding the view
- **Confidence:** 0.85 (from change ui-repositories, domain design; evidence: changes/ui-repositories/00-intake/request.md)

## ask-with-options-after-being-corrected

- **When:** when the user has corrected a misreading and the next step has more than one reasonable direction
- **Do:** put the directions to them with what each costs, and build the one they choose
- **Confidence:** 0.85 (from change ui-repositories, domain intake; evidence: changes/ui-repositories/00-intake/assumptions.md)

## every-limit-states-what-happens-at-the-limit

- **When:** when adding a cap on connections, size, rate, or queue length
- **Do:** decide and test what happens when the cap is reached, from the point of view of a legitimate caller arriving then
- **Confidence:** 0.85 (from change ui-server, domain security; evidence: ATTACK-005, changes/ui-server/09-remediation/summary.md)

## diff-old-and-new-output-when-refactoring-printing-code

- **When:** when refactoring code that produces a command's text output
- **Do:** run the previous commit's code and the new code against the same real data and diff the output and exit codes
- **Confidence:** 0.85 (from change ui-snapshot, domain testing; evidence: changes/ui-snapshot/07-evaluation/evidence/journey-transcript.log)

## exercise-the-real-path-with-a-stand-in

- **When:** when the thing a feature needs (a release, a server, a record) does not exist yet
- **Do:** find the nearest real thing that drives the same code, run it, and record what it could not prove
- **Confidence:** 0.85 (from change update-from-github, domain evaluation; evidence: changes/update-from-github/07-evaluation/evidence/network-transcript.log)

## a-downloads-final-address-is-not-a-file-name

- **When:** when saving a file fetched over HTTP through redirects
- **Do:** name it from what you asked for, not from where the bytes came from
- **Confidence:** 0.85 (from change update-release-asset-name, domain integration; evidence: changes/update-release-asset-name/07-evaluation/evidence/network-transcript.log)

## assert-the-bound-the-code-guarantees-not-a-stopwatch

- **When:** when a test asserts that something happens within a number of seconds
- **Do:** make the bound the one the code guarantees (a timeout, a deadline), not a figure that depends on the machine being idle
- **Confidence:** 0.85 (from change update-release-asset-name, domain testing; evidence: changes/update-release-asset-name/06-verification/results.md)

## never-locate-the-running-rubys-tools-through-path

- **When:** when a Ruby program runs gem, bundle, or ruby as a subprocess
- **Do:** use RbConfig.ruby and RbConfig::CONFIG["bindir"] paths, not ruby -S or a bare name, so a version manager's shim for another Ruby is never picked up
- **Confidence:** 0.85 (from change update-release-asset-name, domain operations; evidence: changes/update-release-asset-name/07-evaluation/evidence/network-transcript.log)

## say-policy-only-at-launch-when-no-hook-exists

- **When:** when launching a session in a host that has no hook mechanism
- **Do:** print one warning at launch that the skill's permissions are policy only for this session, rather than assuming or hiding it
- **Confidence:** 0.80 (from change cross-cli-hooks, domain governance; evidence: changes/cross-cli-hooks/07-evaluation/results.md)

## exempt-list-not-allow-list

- **When:** when a check decides what to enforce from a free-text field such as a severity or status word
- **Do:** list the values that are exempt and enforce on everything else, including a missing value
- **Confidence:** 0.80 (from change cross-provider-review, domain governance; evidence: FIND-ATK-001, changes/cross-provider-review/09-remediation/summary.md)

## build-invisible-and-secret-shapes-at-run-time

- **When:** when a test fixture or an eval case needs an invisible character or a secret-shaped string
- **Do:** substitute a named token at run time; a literal in the file is decoded by the tool that writes it and refused by the scan that reads it
- **Confidence:** 0.80 (from change factory-readiness, domain testing; evidence: changes/factory-readiness/05-implementation/log.md)

## let-the-runner-rerun-what-the-gate-calls-stale

- **When:** when a remediation changes code after an evidence phase completed in a fresh session
- **Do:** let the phase runner accept a complete phase whose gate reports stale evidence instead of asking anyone to edit that phase's handoff
- **Confidence:** 0.80 (from change factory-readiness, domain governance; evidence: REM-001, test/factory_readiness_test.rb)

## name-the-agent-trust-boundary-first

- **When:** when a change launches coding-shell sessions that act on the repository
- **Do:** state in the threat model what those sessions are trusted not to do and what the tool observes, before review
- **Confidence:** 0.80 (from change panel-phases, domain security; evidence: REV-SEC-011, changes/panel-phases/14-judgment/residual-risk.md)

## name-the-phase-that-writes-required-docs

- **When:** when a requirement asks for user documentation or harness-eval cases and the plan lists them as optional phases
- **Do:** record in the plan which phase writes them and do not skip it, since implementation and remediation cannot write docs or .ai
- **Confidence:** 0.80 (from change phase-lifecycle-controls, domain governance; evidence: REV-004, JUDGE-004)

## sweep-neighbouring-values-when-fixing-a-boundary

- **When:** when fixing a bug found with one odd input such as an empty string
- **Do:** list the neighbouring inputs (whitespace, tab, non-breaking space, false, zero) and test each before declaring the boundary fixed
- **Confidence:** 0.80 (from change phase-lifecycle-controls, domain testing; evidence: REV-009, 13-review)

## record-resolved-fact-for-measure-selecting-declarations

- **When:** when a gate takes its measurement base from a value the record's author writes, such as a branch name
- **Do:** record what the value resolved to at the evidence commit and treat any later difference as a stale cause
- **Confidence:** 0.80 (from change scoped-verification, domain security; evidence: REV-001, ATTACK-F-007)

## quote-at-the-point-of-use

- **When:** when a stored value is placed into a shell command, path, or markup for a person to run or view
- **Do:** quote or re-validate it at that point, even if it was validated when it was stored
- **Confidence:** 0.80 (from change session-ledger, domain security; evidence: REV-SEC-001, changes/session-ledger/14-judgment/residual-risk.md)

## recheck-cli-capabilities-against-the-installed-version

- **When:** when the code or docs say an agent CLI lacks a capability (hooks, session ids, skills)
- **Do:** check the installed version's help and bundled docs before building on the claim, and record the version checked
- **Confidence:** 0.80 (from change session-ledger, domain integration; evidence: changes/session-ledger/00-intake/assumptions.md, TM-001)

## check-sibling-command-paths

- **When:** when a change makes a command mark, return or exit with a new status
- **Do:** check every sibling path that calls the same helper (single and parallel run) and assert the process exit status in a test for each
- **Confidence:** 0.80 (from change small-process-fixes, domain testing; evidence: REV-001)

## look-at-the-real-data-before-building-a-view-of-it

- **When:** when asked for a timeline, history, or dashboard over existing records
- **Do:** read what the real records actually hold first, and say in the intake what the view will and will not be able to show
- **Confidence:** 0.80 (from change ui-explainer-timeline, domain design; evidence: changes/ui-explainer-timeline/07-evaluation/results.md)

## a-complaint-phrased-as-a-question-is-a-requirement

- **When:** when the user asks "is this too much to ask" or similar about something missing
- **Do:** treat the thing as a requirement, build it everywhere it applies, and say where it was missing
- **Confidence:** 0.80 (from change ui-links, domain intake; evidence: changes/ui-links/00-intake/request.md)

## a-non-goal-that-excludes-the-obvious-reading-needs-a-question

- **When:** when writing a non-goal or a known limit that leaves out something the request could plainly mean
- **Do:** ask the user before accepting it, rather than recording it as a limit
- **Confidence:** 0.80 (from change ui-processes, domain intake; evidence: changes/ui-processes/05-implementation/deviations.md)

## compare-what-is-recorded-as-started-with-what-is-alive

- **When:** when a record says a run started and nothing says it ended
- **Do:** check whether the process is alive before waiting on it; a start with no finish and no process is an interrupted run to redo
- **Confidence:** 0.80 (from change ui-processes, domain operations; evidence: changes/ui-processes/07-evaluation/evidence/journey-transcript.log)

## a-catch-all-must-say-which-failure-it-caught

- **When:** when one handler covers both a failed request and a fault in handling its answer
- **Do:** report them differently, and log the cause; a programming error must not read as a network problem
- **Confidence:** 0.80 (from change ui-repositories, domain debugging; evidence: changes/ui-repositories/05-implementation/log.md)

## stop-background-servers-in-scripts-with-sigterm

- **When:** when a script starts a server in the background and must stop it
- **Do:** send SIGTERM, not SIGINT; a non-interactive shell starts background jobs with SIGINT ignored
- **Confidence:** 0.80 (from change ui-server, domain testing; evidence: changes/ui-server/05-implementation/log.md)

## read-the-method-before-asserting-on-it

- **When:** when writing a failing test that depends on existing behaviour you have not read
- **Do:** read the method the assertion rests on first, so the test fails for the missing feature and not for a wrong guess
- **Confidence:** 0.80 (from change ui-snapshot, domain testing; evidence: changes/ui-snapshot/05-implementation/deviations.md)

## install-under-the-ruby-that-runs-the-command

- **When:** when a Ruby tool installs or updates itself
- **Do:** run gem through RbConfig.ruby, not the gem on PATH, so the install lands where the command runs
- **Confidence:** 0.80 (from change update-from-github, domain operations; evidence: changes/update-from-github/05-implementation/decisions.md)
