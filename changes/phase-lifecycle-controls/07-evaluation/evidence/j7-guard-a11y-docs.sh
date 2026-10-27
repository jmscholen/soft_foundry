. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
echo "### EVAL-007 guard markers (AC-025,026)"
mk /tmp/evalrun/g1 c1 intake,discover,specify,threat_model,plan,implement,verify in_progress implement; cd /tmp/evalrun/g1
g() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$2" | env SOFT_FOUNDRY_PHASE=$1 ${3:+SOFT_FOUNDRY_PARALLEL=1} SOFT_FOUNDRY_GUARD=block ruby -I$FOUNDRY/lib $FOUNDRY/exe/soft-foundry guard 2>&1 | cut -c1-170; echo "  -> exit=${PIPESTATUS[1]}"; }
echo "current_phase=implement in metadata"
echo "evaluate marker writes app code:"; g evaluate lib/app.rb
echo "evaluate marker writes own dir:"; g evaluate changes/c1/07-evaluation/results.md
echo "evaluate marker writes attack dir:"; g evaluate changes/c1/08-attack/results.md
echo "attack marker writes evaluation dir:"; g attack changes/c1/07-evaluation/results.md
echo "attack marker writes own dir:"; g attack changes/c1/08-attack/results.md
echo "unknown marker:"; g bogus lib/app.rb
echo "implement marker + parallel:"; g implement lib/app.rb par
echo "no marker, current_phase decides (implement may write app):"; printf '{"tool_name":"Edit","tool_input":{"file_path":"lib/app.rb"}}' | env -u SOFT_FOUNDRY_PHASE SOFT_FOUNDRY_GUARD=block ruby -I$FOUNDRY/lib $FOUNDRY/exe/soft-foundry guard; echo "  -> exit=$?"
echo; echo "### EVAL-008 output accessibility (AC-046,047)"
OUTCOME=APPROVED mk /tmp/evalrun/a1 c1 $FIN; cd /tmp/evalrun/a1
: > /tmp/evalrun/a11y.all
S="ruby -I$FOUNDRY/lib $FOUNDRY/exe/soft-foundry"
run() { echo "\$ soft-foundry $*" >> /tmp/evalrun/a11y.all; NO_COLOR=1 $S "$@" < /dev/null 2>&1 | grep -v '^ *! warn' >> /tmp/evalrun/a11y.all; echo "[exit ${PIPESTATUS[0]}]" >> /tmp/evalrun/a11y.all; }
run phase reopen evaluate --reason 'a11y check'
run phase reopen evaluate --reason ''
run phase reopen evaluate --reason again
run change release c1 --item A=a
run change release c1 --item A=a
run change discharge A --note n
run change discharge A --note n
run phase run evaluate attack --parallel --shell nosuch
run phase run evaluate review --parallel
echo "non-ASCII lines in captured output: $(LC_ALL=C grep -c -P '[^\x00-\x7F]' /tmp/evalrun/a11y.all)"
echo "escape-sequence lines: $(LC_ALL=C grep -c -P '\x1b' /tmp/evalrun/a11y.all)"
cp /tmp/evalrun/a11y.all $FOUNDRY/changes/phase-lifecycle-controls/07-evaluation/evidence/a11y-captured-output.txt
cut -c1-190 /tmp/evalrun/a11y.all
echo; echo "### EVAL-009 docs and usage (AC-050): files mentioning each term"
cd $FOUNDRY
for f in .ai/workflow.yml .ai/templates/metadata.yml .ai/schemas.md .ai/README.md README.md docs/user lib/soft_foundry/cli.rb lib/soft_foundry/processes.rb; do
 printf "%-34s" $f; for t in "phase reopen" "--parallel" "--env" "change release" "change discharge"; do printf "[%s]=%s " "$t" "$(grep -rIlF -- "$t" $f 2>/dev/null | wc -l | tr -d ' ')"; done; echo; done
grep -n "isolated_phases" .ai/workflow.yml | head -2; grep -n "phase_reopenings\|release:" .ai/templates/metadata.yml | head
sf check | tail -2
sf eval 2>&1 | tail -2
