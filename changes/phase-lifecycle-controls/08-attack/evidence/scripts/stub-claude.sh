#!/bin/sh
# stub shell for attack driver
out="${STUB_LOG:-/tmp/sfa-stub}"; mkdir -p "$out"
ph="${SOFT_FOUNDRY_PHASE:-none}"
{ echo "argv: $*" | cut -c1-300; env | grep -E 'SOFT_FOUNDRY|DB_URL|SECRET_TOKEN|LOWER' ; echo "pid=$$"; } > "$out/$ph.txt"
[ -n "$STUB_SLEEP" ] && sleep "$STUB_SLEEP"
if [ -n "$STUB_COMMIT" ]; then (cd "$PWD" && echo x >> stubfile.txt && git add stubfile.txt && git commit -qm "stub commit $ph" ); fi
exit "${STUB_EXIT:-0}"
