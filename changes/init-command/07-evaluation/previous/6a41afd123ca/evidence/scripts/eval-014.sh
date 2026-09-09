#!/bin/bash
# EVAL-014: scripting surface: help, unknown options, exit codes. Persona c.
source "$(dirname "$0")/lib.sh"
start_log EVAL-014-cli-surface.log "EVAL-014 agent-facing CLI surface: help text, unknown options, version"
T=$(new_repo eval-014); cd "$T"
printf 'x\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: top-level help"
run $SF; RC1=$?
note "STEP 2: init --help (not a documented option)"
run $SF init --help; RC2=$?
note "STEP 3: init with a misspelled option"
run $SF init --dry_run --no-onboard; RC3=$?
run git status --porcelain --untracked-files=all
note "STEP 4: version"
run $SF version; RC4=$?
note "STEP 5: --root given without a value"
run $SF init --root; RC5=$?
note "ASSERTIONS"
assert "help lists init with all five options, exit 0" "[ $RC1 -eq 0 ] && sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q -- '--dry-run  --force  --no-onboard  --root PATH  --allow-non-git'"
assert "unknown option refused with exit 1 and nothing written" "[ $RC3 -eq 1 ] && sed -n '/STEP 3/,/STEP 4/p' '$LOG' | grep -q 'unknown option(s): --dry_run' && ! sed -n '/STEP 3/,/STEP 4/p' '$LOG' | grep -q '^?? '"
assert "init --help does not install anything" "[ ! -e $T/.ai ]"
assert "version prints a version, exit 0" "[ $RC4 -eq 0 ]"
assert "--root without value refused with exit 1" "[ $RC5 -eq 1 ]"
finish EVAL-014
