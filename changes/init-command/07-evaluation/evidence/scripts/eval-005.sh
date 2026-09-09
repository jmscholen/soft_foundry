#!/bin/bash
# EVAL-005: uncommitted edit to an owned file is a conflict even with --force (MIT-004/MIT-006). Persona b.
source "$(dirname "$0")/lib.sh"
start_log EVAL-005-uncommitted-edit.log "EVAL-005 uncommitted edit is reported conflict and never overwritten, even with --force"
T=$(new_repo eval-005); cd "$T"
printf 'puts 1\n' > app.rb
run git add -A; run git commit -q -m "Project files"
run $SF init --no-onboard
run git add -A; run git commit -q -m "Adopt Soft Foundry"
note "STEP 1: maintainer edits .ai/rules/general.md but does not commit"
runsh "printf '\nWORK IN PROGRESS, not committed\n' >> .ai/rules/general.md"
run git status --porcelain
run shasum -a 256 .ai/rules/general.md
H=$(shasum -a 256 .ai/rules/general.md | cut -d' ' -f1)
note "STEP 2: init without --force"
run $SF init --no-onboard; RC1=$?
note "STEP 3: init with --force"
run $SF init --force --no-onboard; RC2=$?
run shasum -a 256 .ai/rules/general.md
run git status --porcelain
runsh "tail -1 .ai/rules/general.md"
note "ASSERTIONS"
assert "MIT-004 plain run exit 3" "[ $RC1 -eq 3 ]"
assert "MIT-004 plain run reports conflict with reason uncommitted modifications" "sed -n '/STEP 2/,/STEP 3/p' '$LOG' | grep -q '^conflict  .ai/rules/general.md  (uncommitted modifications)'"
assert "MIT-006 --force run still exit 3" "[ $RC2 -eq 3 ]"
assert "MIT-006 --force run still reports conflict, not forced" "sed -n '/STEP 3/,\$p' '$LOG' | grep -q '^conflict  .ai/rules/general.md  (uncommitted modifications)' && ! sed -n '/STEP 3/,\$p' '$LOG' | grep -q '^forced'"
assert "MIT-006 uncommitted edit intact after --force" "[ \"$(shasum -a 256 $T/.ai/rules/general.md | cut -d' ' -f1)\" = \"$H\" ]"
assert "AC-006 check line tells the user to resolve conflicts" "sed -n '/STEP 2/,\$p' '$LOG' | grep -q '^check: '"
finish EVAL-005
