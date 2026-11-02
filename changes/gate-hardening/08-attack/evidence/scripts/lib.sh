# Sourced by each case. fresh NAME copies the template into repos/NAME and cds there.
B=/tmp/sf-attack2/bin; OUT=/tmp/sf-attack2/out; T=/tmp/sf-attack2/repos/template
fresh() { rm -rf /tmp/sf-attack2/repos/$1; cp -R $T /tmp/sf-attack2/repos/$1; cd /tmp/sf-attack2/repos/$1 || exit 9; R=$PWD; }
run() { echo "\$ $*"; "$@"; echo "[exit $?]"; }
log() { echo "--- git log"; git log --format='%h %s' -n 5; echo "--- git status"; git status --porcelain | grep -v 'soft-foundry/' ; echo "--- metadata"; grep -E '^(status|current_phase):' changes/c1/metadata.yml; }
