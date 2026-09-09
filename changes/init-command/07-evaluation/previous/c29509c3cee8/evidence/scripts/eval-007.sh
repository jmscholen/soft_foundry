#!/bin/bash
# EVAL-007: docs/ exists without docs/user/. Persona a.
source "$(dirname "$0")/lib.sh"
start_log EVAL-007-docs-without-user.log "EVAL-007 docs/ present without docs/user/: scaffold skipped with a reason"
T=$(new_repo eval-007); cd "$T"
mkdir -p docs/architecture; printf '# Architecture\n' > docs/architecture/README.md
printf 'x\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: init"
run $SF init --no-onboard; RC1=$?
runsh "ls -A docs; test ! -e docs/user && echo 'docs/user absent'"
note "STEP 2: control case, repository with docs/user/ already present"
T2=$(new_repo eval-007-control); cd "$T2"
mkdir -p docs/user; printf '# Guide\n' > docs/user/guide.md
run git add -A; run git commit -q -m "Project files"
run $SF init --no-onboard; RC2=$?
runsh "ls -A docs/user"
note "ASSERTIONS"
assert "AC-011 exit 0" "[ $RC1 -eq 0 ]"
assert "AC-011 docs/user/README.md reported skipped with reason" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^skipped   docs/user/README.md  (docs/ exists without docs/user/)'"
assert "AC-011 docs/user/README.md not created" "[ ! -e $T/docs/user/README.md ]"
assert "control: docs/user/ present -> README.md created" "[ $RC2 -eq 0 ] && [ -f $T2/docs/user/README.md ] && sed -n '/STEP 2/,\$p' '$LOG' | grep -q '^created   docs/user/README.md'"
finish EVAL-007
