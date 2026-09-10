#!/bin/bash
# EVAL-008: .gitignore already effective (skipped), and .gitignore with other content (appended). Persona b.
source "$(dirname "$0")/lib.sh"
start_log EVAL-008-gitignore.log "EVAL-008 .gitignore already ignoring .soft-foundry/ is skipped and unchanged"
T=$(new_repo eval-008); cd "$T"
printf 'node_modules/\n.soft-foundry/\n*.log\n' > .gitignore
printf 'x\n' > app.js
run git add -A; run git commit -q -m "Project files"
run shasum -a 256 .gitignore
H=$(shasum -a 256 .gitignore | cut -d' ' -f1)
note "STEP 1: init"
run $SF init --no-onboard; RC1=$?
run shasum -a 256 .gitignore
run cat .gitignore
run git status --porcelain -- .gitignore
note "STEP 2: control case, .gitignore present without the line (no trailing newline)"
T2=$(new_repo eval-008-append); cd "$T2"
printf 'node_modules/' > .gitignore
run git add -A; run git commit -q -m "Project files"
run $SF init --no-onboard; RC2=$?
run cat .gitignore
run git check-ignore -v .soft-foundry/runtime.yml
note "ASSERTIONS"
assert "AC-009 exit 0" "[ $RC1 -eq 0 ]"
assert "AC-009 .gitignore reported skipped with reason" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^skipped   .gitignore  (.soft-foundry/ is ignored)'"
assert "AC-009 .gitignore unchanged (hash and git status)" "[ \"$(shasum -a 256 $T/.gitignore | cut -d' ' -f1)\" = \"$H\" ] && [ -z \"$(git -C $T status --porcelain -- .gitignore)\" ]"
assert "control: line appended on its own line, existing content preserved" "[ $RC2 -eq 0 ] && [ \"$(cat $T2/.gitignore)\" = \"$(printf 'node_modules/\n.soft-foundry/')\" ]"
finish EVAL-008
