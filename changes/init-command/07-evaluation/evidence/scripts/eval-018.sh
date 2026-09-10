#!/bin/bash
# EVAL-018: a maintainer with a non-conventional layout gives repository.yml a reasonable,
# non-empty override for APP/TESTS/INFRA (not the protected CONTROL_PLANE/HARNESS_EVALS groups).
# It should work normally: check stays clean, init stays idempotent, nothing is flagged.
# Legitimate-use companion to the V4 remediation (protected-group / emptied-override hardening).
source "$(dirname "$0")/lib.sh"
start_log EVAL-018-repository-yml-override.log "EVAL-018 reasonable non-empty repository.yml path override works normally"
T=$(new_repo eval-018); cd "$T"
mkdir -p src/widgets spec infra
printf 'puts 1\n' > src/widgets/app.rb
printf 'assert true\n' > spec/app_spec.rb
printf 'resource "x" {}\n' > infra/main.tf
run git add -A; run git commit -q -m "Non-conventional layout: src/, spec/, infra/"
note "STEP 1: first install"
run $SF init --no-onboard; RC1=$?
run $SF check; RC1C=$?
note "STEP 2: maintainer overrides APP/TESTS/INFRA to match their real layout"
runsh "$RUBY -ryaml -e '
d = YAML.safe_load(File.read(\".ai/repository.yml\"))
d[\"paths\"] = {\"APP\" => [\"src/**\"], \"TESTS\" => [\"spec/**\"], \"INFRA\" => [\"infra/**\"]}
File.write(\".ai/repository.yml\", YAML.dump(d))
' && echo 'override written'"
run cat .ai/repository.yml
run git add -A; run git commit -q -m "Override path groups for our layout"
note "STEP 3: check and a second init run after the legitimate override"
run $SF check; RC2=$?
run $SF init --no-onboard; RC3=$?
run git status --porcelain
note "STEP 4: control -- a protected-group override is still rejected (contrast, not a violation of this journey)"
runsh "$RUBY -ryaml -e '
d = YAML.safe_load(File.read(\".ai/repository.yml\"))
d[\"paths\"][\"HARNESS_EVALS\"] = [\"nothing/**\"]
File.write(\".ai/repository.yml\", YAML.dump(d))
' && echo 'protected override written'"
run $SF check; RC4=$?
runsh "git checkout -- .ai/repository.yml; echo reverted"
note "ASSERTIONS"
assert "setup: first install exit 0" "[ $RC1 -eq 0 ]"
assert "setup: check passes before any override" "[ $RC1C -eq 0 ]"
assert "the override file was written with all three groups" "grep -q 'src/\\*\\*' $T/.ai/repository.yml && grep -q 'spec/\\*\\*' $T/.ai/repository.yml && grep -q 'infra/\\*\\*' $T/.ai/repository.yml"
assert "check passes with the reasonable APP/TESTS/INFRA override (no error)" "[ $RC2 -eq 0 ] && sed -n '/STEP 3/,/STEP 4/p' '$LOG' | grep -q 'control plane: .* no errors'"
assert "init stays idempotent after the override (exit 0, no conflicts, repository.yml skipped, git clean)" "[ $RC3 -eq 0 ] && sed -n '/STEP 3/,/STEP 4/p' '$LOG' | grep -q '^skipped   .ai/repository.yml' && [ -z \"\$(git -C $T status --porcelain)\" ]"
assert "control: a protected-group (HARNESS_EVALS) override is still rejected, exit 2" "[ $RC4 -eq 2 ] && sed -n '/STEP 4/,\$p' '$LOG' | grep -q 'overrides protected path group HARNESS_EVALS'"
finish EVAL-018
