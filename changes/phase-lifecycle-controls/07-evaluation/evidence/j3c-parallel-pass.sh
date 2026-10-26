. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export PATH=/tmp/evalrun/bin:$PATH
UPTO=intake,discover,specify,threat_model,plan,implement,verify
echo "### EVAL-003c parallel with passing stubs (AC-030,031,032)"
mk /tmp/evalrun/r1 c1 $UPTO in_progress verify; cd /tmp/evalrun/r1
sf phase run evaluate attack --parallel --shell claude --env X=1 2>&1 | grep -E '^(phase [a-z]+:|parallel:|warn)'; echo "exit=${PIPESTATUS[0]}"
grep ^current_phase changes/c1/metadata.yml; git log --oneline | head -1; git rev-parse --short HEAD
echo "--- one passes, one fails"
mk /tmp/evalrun/r2 c1 $UPTO in_progress verify; cd /tmp/evalrun/r2
STUB_FAIL=attack sf phase run evaluate attack --parallel --shell claude --env X=1 2>&1 | grep -E '^(phase [a-z]+:|parallel:)'; echo "exit=${PIPESTATUS[0]}"
echo "--- stub commits (AC-032 warn)"
export STUB_COMMIT=1
mk /tmp/evalrun/r3 c1 $UPTO in_progress verify; cd /tmp/evalrun/r3
sf phase run evaluate attack --parallel --shell claude --env X=1 2>&1 | grep -E '^(phase [a-z]+:|parallel:|warn)'; echo "exit=${PIPESTATUS[0]}"
unset STUB_COMMIT
