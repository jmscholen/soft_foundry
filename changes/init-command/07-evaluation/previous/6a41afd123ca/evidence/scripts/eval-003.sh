#!/bin/bash
# EVAL-003: dry-run preview then real run. Persona c (agent scripting on the report).
source "$(dirname "$0")/lib.sh"
start_log EVAL-003-dry-run-then-real.log "EVAL-003 dry-run preview matches the real run and writes nothing"
T=$(new_repo eval-003); cd "$T"
printf 'fn main() {}\n' > main.rs
run git add -A; run git commit -q -m "Project files"
note "STEP 1: dry run"
run $SF init --dry-run --no-onboard; RC1=$?
sed -n '/STEP 1: dry run/,/^exit=/p' "$LOG" | grep -vE '^(\$|exit=|###)' > "$SCRATCH/eval-003-dry.txt"
note "STEP 1 post-state"
run git status --porcelain --untracked-files=all
runsh "ls -A"
runsh "test ! -e .ai/manifest.yml && echo 'no manifest' "
[ -e .ai ] && DRY_AI=1 || DRY_AI=0
[ -e .soft-foundry ] && DRY_SF=1 || DRY_SF=0
note "STEP 2: real run"
run $SF init --no-onboard; RC2=$?
sed -n '/STEP 2: real run/,/^exit=/p' "$LOG" | grep -vE '^(\$|exit=|###)' > "$SCRATCH/eval-003-real.txt"
note "STEP 3: compare reports (dry-run report minus its 'mode:' line, real report minus its 'check:' line)"
runsh "diff <(grep -v '^mode:' $SCRATCH/eval-003-dry.txt) <(grep -v '^check:' $SCRATCH/eval-003-real.txt) && echo 'reports identical apart from mode/check lines'"
SAME=$?
runsh "grep -E '^(mode|check|summary):' $SCRATCH/eval-003-dry.txt $SCRATCH/eval-003-real.txt"
note "ASSERTIONS"
assert "AC-012 dry run exit 0" "[ $RC1 -eq 0 ]"
assert "AC-012 dry run prints mode line" "grep -q '^mode: dry run, nothing written' $SCRATCH/eval-003-dry.txt"
assert "AC-012 dry run wrote nothing (git clean, no untracked)" "sed -n '/STEP 1 post-state/,/STEP 2/p' '$LOG' | grep -q 'no manifest' && ! sed -n '/STEP 1 post-state/,/STEP 2/p' '$LOG' | grep -Eq '^\?\? '"
assert "AC-012 dry run did not create .ai or .soft-foundry" "[ $DRY_AI -eq 0 ] && [ $DRY_SF -eq 0 ]"
assert "AC-012 real run exit 0" "[ $RC2 -eq 0 ]"
assert "AC-012 real report matches dry-run report" "[ $SAME -eq 0 ]"
assert "AC-012 real run wrote the manifest" "[ -f $T/.ai/manifest.yml ]"
finish EVAL-003
