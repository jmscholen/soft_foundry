#!/bin/sh
# Verification probe: drives the worktree's CLI against a throwaway repository.
# Usage: cli-probe.sh <repository root of the change under verification>
ROOT="$1"; D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
sf() { env -u SOFT_FOUNDRY_PHASE NO_COLOR=1 ruby -I"$ROOT/lib" "$ROOT/exe/soft-foundry" "$@"; echo "[exit $?]"; }
cp -R "$ROOT/.ai" "$D/"; mkdir -p "$D/lib" "$D/docs"; echo 'puts 1' > "$D/lib/app.rb"; echo '# agents' > "$D/AGENTS.md"
cd "$D" && git init -q -b main && git config user.email t@example.com && git config user.name T && git add . && git commit -qm initial
git checkout -qb change/p1
echo '## 1. change new --track nosuch'; sf change new p1 --track nosuch 2>&1
echo '## 2. change new --track light'; sf change new p1 --track light 2>&1
grep -n '^track:' changes/p1/metadata.yml
git add -A && git commit -qm record; BASE=$(git rev-parse HEAD)
echo '## 3. change status, colour off, non-ASCII removed'; sf change status p1 2>&1 | LC_ALL=C tr -cd '\11\12\40-\176'
echo '## 4. text-only diff: change size --phase verify'
echo '# readme' > README.md; echo guide > docs/guide.md; echo 'One more sentence.' >> .ai/skills/review/SKILL.md; echo log > changes/p1/05-implementation/log.md
git add -A && git commit -qm text; sf change size --phase verify --since "$BASE" 2>&1
echo '## 5. same plus a path under lib/'
echo 'puts 3' > lib/app.rb; git add -A && git commit -qm code; sf change size --phase verify --since "$BASE" 2>&1
echo '## 6. control-plane settings file instead of lib/ (must not be text)'
git reset -q --hard HEAD~1; echo '# c' >> .ai/workflow.yml; git add -A && git commit -qm yml; sf change size --phase verify --since "$BASE" 2>&1
