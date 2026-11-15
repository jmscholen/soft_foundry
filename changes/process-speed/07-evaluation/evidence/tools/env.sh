WT=/Users/jscholen-iou/dev/soft_foundry/.claude/worktrees/process-speed
S=<scratch repo for EVAL-001..003>
sf(){ env -u SOFT_FOUNDRY_PHASE -u SOFT_FOUNDRY_PARALLEL NO_COLOR=1 /Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby -I$WT/lib $WT/exe/soft-foundry "$@"; }
complete(){ env -u SOFT_FOUNDRY_PHASE -u SOFT_FOUNDRY_PARALLEL /Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby -I$WT/lib /tmp/sf-eval-tools/complete.rb "$@"; }
