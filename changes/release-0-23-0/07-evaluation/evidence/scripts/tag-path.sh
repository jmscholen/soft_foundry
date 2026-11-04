#!/bin/bash
# Rehearses .github/workflows/release.yml in order, minus `gh release create`.
source /tmp/sf-eval-scripts/clean.sh
SRC=/Users/jscholen-iou/dev/soft_foundry/.claude/worktrees/precommit-ci-scope
S=$1; TAG=v0.23.0
echo "source HEAD: $(git -C $SRC rev-parse HEAD)"
mkdir -p $S/repo $S/home; cd $S/repo
git init -q . && git fetch -q --depth=1 "file://$SRC" "+HEAD:refs/tags/$TAG" && git checkout -q "refs/tags/$TAG"
echo "checkout: shallow=$(git rev-parse --is-shallow-repository) head=$(git rev-parse HEAD) branch=[$(git branch --show-current)] commits=$(git rev-list --count HEAD)"
export SF_HOME=$S/home
echo "--- step: bundle install (bundler-cache)"; clean bundle install --local 2>&1 | tail -2; echo "rc=${PIPESTATUS[0]}"
echo "--- step: tag must be the version in the code"
step='version="$(ruby -Ilib exe/soft-foundry version)"; test "v${version}" = "${GITHUB_REF_NAME}" || { echo "tag ${GITHUB_REF_NAME} but lib/soft_foundry/version.rb says ${version}"; exit 1; }'
clean GITHUB_REF_NAME=$TAG bash -e -c "$step"; echo "matching tag rc=$? (expect 0)"
clean GITHUB_REF_NAME=v0.22.0 bash -e -c "$step"; echo "mismatched tag rc=$? (expect 1)"
echo "--- step: bundle exec rake test"; date -u +%FT%TZ
clean CI=true GITHUB_ACTIONS=true GITHUB_REF_NAME=$TAG bundle exec rake test 2>&1 | tail -25; echo "rc=${PIPESTATUS[0]}"; date -u +%FT%TZ
echo "--- step: gem build"; clean gem build soft_foundry.gemspec 2>&1; echo "rc=$?"
echo "--- step: asset glob"; ls -1 soft_foundry-*.gem; shasum -a 256 soft_foundry-*.gem
echo "--- step: gh release create NOT RUN (outward-facing; needs the person's go-ahead)"
