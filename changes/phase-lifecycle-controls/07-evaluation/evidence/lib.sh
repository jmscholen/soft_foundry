export FOUNDRY=/Users/jscholen-iou/dev/soft_foundry
unset ANTHROPIC_API_KEY OPENAI_API_KEY XAI_API_KEY OPENROUTER_API_KEY MAILTRAP_API_KEY PERSONAL_SENDGRID_API_KEY SOFT_FOUNDRY_PHASE SOFT_FOUNDRY_PARALLEL
sf() { ruby -I$FOUNDRY/lib $FOUNDRY/exe/soft-foundry "$@"; }
mk() { ruby -I$FOUNDRY/lib $FOUNDRY/changes/phase-lifecycle-controls/07-evaluation/evidence/mkrepo.rb "$@" >/dev/null; }
ALL=intake,discover,specify,threat_model,plan,implement,verify,evaluate,attack,review
st() { grep -h '^status:' changes/*/*/handoff.yml | sort | uniq -c | tr '\n' ' '; echo; }
FIN=$ALL,judge,learn
