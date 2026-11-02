# frozen_string_literal: true

# A stand-in for a coding shell, launched by `soft-foundry phase run` as
# `claude -p --session-id ID --name NAME PROMPT` (the driver puts a `claude`
# wrapper that runs this file first on PATH). It behaves as the environment
# tells it (SF_EVAL_BEHAVIOUR_<PHASE> or SF_EVAL_BEHAVIOUR):
#   complete     fill the phase from its templates and mark it complete at HEAD
#   in_progress  return without touching the handoff
#   blocked      write status blocked with a blocking entry
#   fail         exit 1 without touching the handoff
#   sleep:N      wait N seconds, then complete
# It records the prompt, its arguments and the NAMES of its environment
# variables (never values) under <scratch>/sessions/ for inspection.
require "soft_foundry"
require "yaml"
require "fileutils"

phase_id = ENV["SOFT_FOUNDRY_PHASE"].to_s
root = Dir.pwd
prompt = ARGV.last.to_s
slug = `git rev-parse --abbrev-ref HEAD`.strip.sub(%r{\Achange/}, "")
behaviour = ENV["SF_EVAL_BEHAVIOUR_#{phase_id.upcase}"] || ENV["SF_EVAL_BEHAVIOUR"] || "complete"

log_dir = File.join(ENV.fetch("SF_EVAL_SCRATCH", "/tmp/sf-eval"), "sessions")
FileUtils.mkdir_p(log_dir)
base = File.join(log_dir, "#{Time.now.strftime('%H%M%S')}-#{slug}-#{phase_id}")
File.write("#{base}.prompt.txt", prompt)
File.write("#{base}.args.txt", ARGV[0..-2].join(" ") + "\n")
File.write("#{base}.env-names.txt", ENV.keys.select { |k| k.start_with?("SOFT_FOUNDRY_", "SECRET", "SF_EVAL") }.sort.join("\n") + "\n")
File.write("#{base}.behaviour.txt", behaviour + "\n")

plane = SoftFoundry::ControlPlane.new(root)
record = SoftFoundry::ChangeRecord.new(root, slug, control_plane: plane)
phase = plane.phase(phase_id)
head = `git rev-parse HEAD`.strip

case behaviour
when "complete"
  SoftFoundry::HarnessEval.complete_phase!(record, phase_id, head, runner: false)
when "in_progress"
  # leave the handoff as the runner left it
when "blocked"
  record.update_handoff(phase) do |h|
    h["status"] = "blocked"
    h["blocking"] = [{ "id" => "BLK-001", "summary" => "the fixture under test could not be started" }]
  end
when "fail"
  warn "fake session: failing as instructed"
  exit 1
when /\Asleep:(\d+)\z/
  sleep(Regexp.last_match(1).to_i)
  SoftFoundry::HarnessEval.complete_phase!(record, phase_id, head, runner: false)
else
  warn "fake session: unknown behaviour #{behaviour}"
  exit 1
end
exit 0
