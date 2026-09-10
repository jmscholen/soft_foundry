#!/bin/bash
# EVAL-009: --root pointing at a subdirectory is refused; --root at top-level works and the root is printed. Persona c.
source "$(dirname "$0")/lib.sh"
start_log EVAL-009-root-option.log "EVAL-009 --root must be the repository top-level; resolved root is printed"
T=$(new_repo eval-009); cd "$T"
mkdir -p services/api; printf 'x\n' > services/api/app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: --root at a subdirectory, invoked from outside the repository"
cd "$SCRATCH"
run $SF init --root "$T/services/api" --no-onboard; RC1=$?
run git -C "$T" status --porcelain --untracked-files=all
note "STEP 2: invoked from inside the subdirectory without --root (cwd is used, top-level resolved)"
cd "$T/services/api"
run $SF init --dry-run --no-onboard; RC2=$?
note "STEP 3: --root at the top-level from outside"
cd "$SCRATCH"
run $SF init --root "$T" --no-onboard; RC3=$?
note "STEP 4: --root that does not exist"
run $SF init --root "$SCRATCH/does-not-exist" --no-onboard; RC4=$?
note "ASSERTIONS"
assert "MIT-008 --root subdirectory refused, exit 1" "[ $RC1 -eq 1 ]"
assert "MIT-008 refusal names the top-level" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q -- \"--root must be the repository top-level ($T)\""
assert "MIT-008 nothing written on refusal" "! sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q '^?? '"
assert "AC-001 cwd inside subdirectory resolves to top-level and prints root" "[ $RC2 -eq 0 ] && sed -n '/STEP 2/,/STEP 3/p' '$LOG' | grep -q \"^root: $T\$\""
assert "AC-001 --root top-level installs, exit 0, root printed" "[ $RC3 -eq 0 ] && sed -n '/STEP 3/,/STEP 4/p' '$LOG' | grep -q \"^root: $T\$\" && [ -f $T/.ai/manifest.yml ]"
assert "missing --root directory refused, exit 1" "[ $RC4 -eq 1 ] && sed -n '/STEP 4/,\$p' '$LOG' | grep -q 'is not a directory'"
finish EVAL-009
