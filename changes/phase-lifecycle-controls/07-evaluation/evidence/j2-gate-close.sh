. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
echo "### EVAL-002 reopened phase cannot pass; close refuses (AC-014,015)"
mk /tmp/evalrun/j2 c1 $ALL; cd /tmp/evalrun/j2
sf phase reopen specify --reason 'spec wrong'; echo "exit=$?"
sf change status | sed -n 1,12p
echo "--- gate specify / gate all exit"; sf gate specify >/dev/null; echo "gate specify exit=$?"; sf gate all >/dev/null 2>&1; echo "gate all exit=$?"
echo "--- baseline: a never-started pending phase, gate exit"; mk /tmp/evalrun/j2b c1 intake; cd /tmp/evalrun/j2b; sf gate discover >/dev/null; echo "gate pending(pre-existing behaviour) exit=$?"; sf gate all >/dev/null 2>&1; echo "gate all exit=$?"
echo "--- close refuses"; cd /tmp/evalrun/j2; sf change close c1; echo "exit=$?"
echo "--- ci on reopened record"; sf ci >/dev/null 2>&1; echo "ci exit=$?"
echo "--- AC-002 reopen remediate"
mk /tmp/evalrun/j2c c1 $ALL,remediate; cd /tmp/evalrun/j2c; sf change status | grep -c complete
sf phase reopen remediate --reason r; echo "exit=$?"
echo "--- AC-003 waived optional phases untouched"
mk /tmp/evalrun/j2d c1 $ALL; cd /tmp/evalrun/j2d; sed -i.bak 's/^skipped_phases: \[\]/skipped_phases:\n- phase: document\n  rationale: n\/a\n- phase: index\n  rationale: n\/a/' changes/c1/metadata.yml; rm changes/c1/metadata.yml.bak; git commit -qam waive
md5 -q changes/c1/10-user-documentation/handoff.yml changes/c1/11-faq-index/handoff.yml > /tmp/evalrun/pre.md5
sf phase reopen attack --reason r; echo "exit=$?"
md5 -q changes/c1/10-user-documentation/handoff.yml changes/c1/11-faq-index/handoff.yml | diff - /tmp/evalrun/pre.md5 && echo "waived pending handoffs byte-identical"
echo "--- AC-010 judge reopen"
mk /tmp/evalrun/j2e c1 $ALL,judge judged judge; cd /tmp/evalrun/j2e; sf phase reopen judge --reason r; echo "exit=$?"; grep -E '^(status|current_phase)' changes/c1/metadata.yml
mk /tmp/evalrun/j2f c1 $ALL,judge intake judge; cd /tmp/evalrun/j2f; sf phase reopen judge --reason r >/dev/null; grep -E '^(status|current_phase)' changes/c1/metadata.yml
echo "--- AC-011 statuses"
for s in closed released exploring awaiting_human; do mk /tmp/evalrun/j2s c1 $ALL $s judge; (cd /tmp/evalrun/j2s; sf phase reopen evaluate --reason r; echo "$s exit=$?"; git status --porcelain | grep -v soft-foundry | wc -l); done
