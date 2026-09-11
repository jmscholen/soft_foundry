# Evaluation Plan

Walk the actual failure mode this change fixes, end to end, against a real scratch repository carrying this repository's own real `.ai/` control plane and the actual CLI (not a synthetic fixture, not a unit test mock): create a change, complete it through judgment with one undischarged acceptance criterion, merge it into `main` without closing it, and confirm:

1. `ci` catches the un-closed record and says so, with the exact remediation command.
2. `change close` refuses on its own, naming the undischarged criterion.
3. `change close --confirm <id>` succeeds once a human explicitly attests to it.
4. `ci` is clean afterward.

Accessibility is not applicable — a non-interactive CLI with plain-text output.
