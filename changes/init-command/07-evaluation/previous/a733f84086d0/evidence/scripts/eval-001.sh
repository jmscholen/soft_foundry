#!/bin/bash
# EVAL-001: first-time adoption, commit, re-run (idempotency). Persona a.
source "$(dirname "$0")/lib.sh"
start_log EVAL-001-first-install-idempotent.log "EVAL-001 first install, commit, re-run"
T=$(new_repo eval-001); cd "$T"
printf 'puts "hello"\n' > app.rb
run git add app.rb; run git commit -q -m "Add application file"
run shasum -a 256 app.rb
APP_BEFORE=$(shasum -a 256 app.rb | cut -d' ' -f1)
note "STEP 1: first run"
run $SF init --no-onboard; RC1=$?
note "STEP 1 post-state"
run git status --porcelain
runsh "ls -A"
runsh "ls -A .ai .ai/harness-evals"
run head -8 .ai/manifest.yml
runsh "grep -c '^  ' .ai/manifest.yml"
run grep -n "assessed" .ai/repository.yml
run cat .gitignore
run cat AGENTS.md
run cat CLAUDE.md
run git check-ignore -v .soft-foundry/runtime.yml
note "STEP 1 manifest integrity: recompute every listed hash and compare to on-disk .ai/ files"
runsh "$RUBY -ryaml -rdigest -e '
m = YAML.safe_load(File.read(\".ai/manifest.yml\"))
files = m[\"files\"]
bad = files.reject { |p, h| File.file?(p) && Digest::SHA256.file(p).hexdigest == h }
ondisk = Dir.glob(\".ai/**/*\", File::FNM_DOTMATCH).select { |f| File.file?(f) } - [\".ai/manifest.yml\", \".ai/repository.yml\"]
missing = ondisk - files.keys
puts \"manifest entries=#{files.size} hash mismatches=#{bad.size} on-disk .ai files not in manifest=#{missing.inspect} version=#{m[\"soft_foundry_version\"]}\"
exit((bad.empty? && missing.empty?) ? 0 : 1)'"
MANIFEST_OK=$?
note "STEP 1 canonical comparison: every installed .ai/ file (except repository.yml) is byte-identical to the packaged source; repository.yml equals the template"
runsh "cd $T && for f in \$(find .ai -type f | sort); do case \$f in .ai/manifest.yml) continue;; .ai/repository.yml) cmp -s \$f $REPO/.ai/templates/repository.yml || echo DIFF \$f;; *) cmp -s \$f $REPO/\$f || echo DIFF \$f;; esac; done; echo compared"
run $SF check
run $SF doctor
note "STEP 2: commit the install"
run git add -A; run git commit -q -m "Adopt Soft Foundry"
run git status --porcelain
runsh "find .ai AGENTS.md CLAUDE.md .gitignore changes docs -type f -exec stat -f '%m %N' {} + | sort > $SCRATCH/eval-001-mtimes-before.txt; wc -l $SCRATCH/eval-001-mtimes-before.txt"
sleep 1
note "STEP 3: second run"
run $SF init --no-onboard; RC2=$?
runsh "find .ai AGENTS.md CLAUDE.md .gitignore changes docs -type f -exec stat -f '%m %N' {} + | sort > $SCRATCH/eval-001-mtimes-after.txt; diff $SCRATCH/eval-001-mtimes-before.txt $SCRATCH/eval-001-mtimes-after.txt && echo 'mtimes identical'"
MT=$?
run git status --porcelain
runsh "grep -c '^skipped ' $LOG"
note "ASSERTIONS"
assert "AC-001 first run exit 0" "[ $RC1 -eq 0 ]"
assert "AC-001 report starts with root: line naming the target" "sed -n '/STEP 1: first run/,/exit=/p' '$LOG' | grep -q '^root: $T\$'"
assert "AC-001 check: ok printed" "grep -q '^check: ok' '$LOG'"
assert "AC-001 application file byte-identical" "[ \"$(shasum -a 256 $T/app.rb | cut -d' ' -f1)\" = \"$APP_BEFORE\" ]"
assert "AC-001 manifest lists every .ai file with matching SHA-256" "[ $MANIFEST_OK -eq 0 ]"
assert "AC-001 installed .ai/ is byte-identical to packaged canonical set" "! grep -q '^DIFF ' '$LOG'"
assert "AC-001 changes/README.md exists" "[ -f $T/changes/README.md ]"
assert "AC-001 .gitignore contains .soft-foundry/" "grep -qx '.soft-foundry/' $T/.gitignore"
assert "AC-001 AGENTS.md and CLAUDE.md carry the marker" "grep -q 'soft-foundry:begin' $T/AGENTS.md && grep -q 'soft-foundry:begin' $T/CLAUDE.md"
assert "AC-001 soft-foundry check passes in target" "cd $T && $SF check >/dev/null 2>&1"
assert "AC-010 repository.yml assessed false with empty capabilities" "grep -q 'assessed: false' $T/.ai/repository.yml && grep -q 'capabilities: {}' $T/.ai/repository.yml"
assert "AC-010 harness-evals contains only README.md" "[ \"$(ls -A $T/.ai/harness-evals)\" = 'README.md' ]"
assert "AC-003 second run exit 0" "[ $RC2 -eq 0 ]"
assert "AC-003 second run reports only skipped (no created/updated/conflict/forced)" "! sed -n '/STEP 3: second run/,/exit=/p' '$LOG' | grep -Eq '^(created|updated|conflict|forced) '"
assert "AC-003 second run summary shows zero created" "sed -n '/STEP 3: second run/,/exit=/p' '$LOG' | grep -q '^summary: created 0, updated 0, skipped [0-9]*, conflict 0, forced 0'"
assert "AC-003 git status clean after second run" "[ -z \"$(git -C $T status --porcelain)\" ]"
assert "AC-003 (stretch) modification times unchanged" "[ $MT -eq 0 ]"
finish EVAL-001
