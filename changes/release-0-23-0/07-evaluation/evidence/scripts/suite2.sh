#!/bin/bash
cd /private/tmp/sf-eval.NdXf2e/repo; date -u +%FT%TZ
echo "HEAD $(git rev-parse HEAD) shallow=$(git rev-parse --is-shallow-repository) branch=[$(git branch --show-current)] status=[$(git status --short | grep -v Gemfile.lock | grep -v '\.gem$' | wc -l | tr -d ' ')]"
echo "PATH: ruby, /usr/bin, /bin only: no claude, codex, grok or gh. HOME on a resolved path. No global git config. No provider keys."
env -i PATH=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin:/usr/bin:/bin:/usr/sbin:/sbin HOME=/private/tmp/sf-eval.NdXf2e/home3 TMPDIR=/tmp LANG=en_US.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 CI=true GITHUB_ACTIONS=true GITHUB_REF_NAME=v0.23.0 bundle exec rake test 2>&1 | tail -30
echo "rc=${PIPESTATUS[0]}"; date -u +%FT%TZ
