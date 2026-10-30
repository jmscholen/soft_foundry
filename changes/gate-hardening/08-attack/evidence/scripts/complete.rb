#!/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
# complete.rb DIR PHASE [SHA|HEAD] [--no-runner]: completes a phase on disk the way the suite's fixture does.
require "open3"
$LOAD_PATH.unshift "/Users/jscholen-iou/dev/soft_foundry/lib"
require "soft_foundry"
require "soft_foundry/harness_eval"
dir, phase, sha = ARGV[0], ARGV[1], (ARGV[2] || "HEAD")
sha = Open3.capture2("git", "-C", dir, "rev-parse", sha).first.strip unless sha.match?(/\A[0-9a-f]{40}\z/)
plane = SoftFoundry::ControlPlane.new(dir)
record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
SoftFoundry::HarnessEval.complete_phase!(record, phase, sha, runner: !ARGV.include?("--no-runner"))
puts "completed #{phase} at #{sha[0, 12]}#{ARGV.include?('--no-runner') ? ' (no executed_by)' : ''}"
