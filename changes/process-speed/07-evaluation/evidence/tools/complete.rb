require "soft_foundry"
dir, slug, *ids = ARGV
plane = SoftFoundry::ControlPlane.new(dir)
record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane)
sha = `git -C #{dir} rev-parse HEAD`.strip
ids.each { |id| SoftFoundry::HarnessEval.complete_phase!(record, id, sha) }
