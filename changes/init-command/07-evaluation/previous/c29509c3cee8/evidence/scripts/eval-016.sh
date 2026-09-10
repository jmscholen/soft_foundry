#!/bin/bash
# EVAL-016: dry-run preview of an upgrade that has a conflict: report shows conflicts/next, exit 3, nothing written. Persona c.
source "$(dirname "$0")/lib.sh"
start_log EVAL-016-dry-run-conflict-preview.log "EVAL-016 dry-run preview of a conflicting upgrade shows conflicts:/next: guidance, exits 3, writes nothing"
T=$(new_repo eval-016); cd "$T"
printf 'x\n' > app.rb
run git add -A; run git commit -q -m "Project files"
run $SF init --no-onboard
run git add -A; run git commit -q -m "Adopt Soft Foundry"
runsh "printf '\n# team rule\n' >> .ai/rules/errors.md; git add -A; git commit -q -m 'Team rule'; echo committed"
run git rev-parse --short HEAD
note "STEP 1: dry-run preview"
run $SF init --dry-run --no-onboard; RC1=$?
run git status --porcelain --untracked-files=all
runsh "tail -1 .ai/rules/errors.md"
note "STEP 2: dry-run preview with --force shows the would-be forced set, still writes nothing"
run $SF init --dry-run --force --no-onboard; RC2=$?
run git status --porcelain --untracked-files=all
runsh "tail -1 .ai/rules/errors.md"
note "ASSERTIONS"
assert "AC-012 dry run with a conflict exits 3 (same code a real run would return)" "[ $RC1 -eq 3 ]"
assert "AC-012 dry run prints mode line, conflict line, conflicts: and next: lines" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^mode: dry run, nothing written' && sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^conflict  .ai/rules/errors.md  (differs from manifest hash)' && sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^conflicts: .ai/rules/errors.md\$' && sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^next: '"
assert "AC-012 dry run wrote nothing (git clean, team rule intact)" "[ -z \"$(git -C $T status --porcelain --untracked-files=all)\" ] && grep -q '# team rule' $T/.ai/rules/errors.md"
assert "MIT-006 dry run with --force shows forced, exit 0, and still writes nothing" "[ $RC2 -eq 0 ] && sed -n '/STEP 2/,\$p' '$LOG' | grep -q '^forced    .ai/rules/errors.md' && grep -q '# team rule' $T/.ai/rules/errors.md && [ -z \"$(git -C $T status --porcelain --untracked-files=all)\" ]"
finish EVAL-016
