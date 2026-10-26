. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
echo "### EVAL-005 released record among consumers (AC-044,046,048,049)"
OUTCOME=APPROVED mk /tmp/evalrun/c1r c1 $FIN; cd /tmp/evalrun/c1r
sf change release --item GOLIVE-1='switch flag on' --item GOLIVE-2='watch error rate' >/dev/null
sf phase reopen evaluate --reason r >/dev/null 2>&1 ; git checkout -q -b change/c2; sf change new c2 >/dev/null; git add -A; git commit -qm c2
echo "--- change status (released)"; sf change status c1 2>&1 | head -4
echo "--- change list --json (released entry)"; sf change list --json | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts JSON.pretty_generate(j.is_a?(Hash) ? (j["changes"]||j).select{|c| c["slug"]=="c1"||c["id"]=="c1"} : j.select{|c| c["slug"]=="c1"||c["id"]=="c1"})' | head -30
echo "--- gate all: released not evaluated for staleness"; echo 'x' >> lib/app.rb; git commit -qam "code change"; sf gate all 2>&1 | grep -E 'c1|released|stale|current' | head
echo "--- ci"; sf ci 2>&1 | grep -E 'c1|c2|released|ci ' | head
echo "--- scope check / learn"; sf learn list 2>&1 | head -3; sf learn promote --dry-run 2>&1 | head -3
echo "--- ps"; sf ps 2>&1 | head -8
echo "--- ui api"
sf ui --port 0 > /tmp/evalrun/ui.out 2>&1 & UP=$!; sleep 2; URL=$(grep -o 'http://[^ ]*' /tmp/evalrun/ui.out | head -1); TOK=${URL##*token=}; BASE=${URL%%/#*}; echo "url shape: ${BASE}/#token=<redacted>"
curl -s -H "x-soft-foundry-token: $TOK" "$BASE/api/changes" | ruby -rjson -e 'j=JSON.parse(STDIN.read); s=JSON.pretty_generate(j); puts s.lines.grep(/released|open_items|open item|GOLIVE|"status"/).first(14)'
curl -s -o /dev/null -w "no token -> HTTP %{http_code}\n" "$BASE/api/changes"
curl -s "$BASE/app.js" | grep -n "released\|open item\|<th\|th(" | head -12
curl -s "$BASE/app.css" | grep -n "released" | head
kill $UP; wait $UP 2>/dev/null
