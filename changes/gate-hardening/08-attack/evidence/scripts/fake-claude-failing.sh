#!/bin/sh
# Fake shell for ATTACK-013: records that it ran and whether SECRET reached it (never its value), then fails.
echo "fake claude ran: phase=$SOFT_FOUNDRY_PHASE SECRET-set=${SECRET:+yes} args=$#" >> /tmp/sf-attack2/out/fake-claude.log
exit 1
