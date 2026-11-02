#!/bin/sh
# Fake shell for ATTACK-008b: completes the evaluate handoff like a session would, lingers, exits 0.
/tmp/sf-attack2/bin/complete.rb "$PWD" "$SOFT_FOUNDRY_PHASE" HEAD --no-runner >> /tmp/sf-attack2/out/fake-claude.log 2>&1
sleep 2
exit 0
