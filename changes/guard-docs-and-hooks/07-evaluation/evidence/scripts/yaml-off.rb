# EVAL-004 follow-up: the header documents three modes, warn, block, and off.
# A YAML 1.1 parser reads an unquoted `off` as the boolean false, so what does
# Guard.mode report for a policy or override written as the header spells it?
# Runs against throwaway directories only. Run as:
#   ruby -Ilib changes/guard-docs-and-hooks/07-evaluation/evidence/scripts/yaml-off.rb
require "tmpdir"
require "fileutils"
require "yaml"
require "soft_foundry"

puts "YAML.safe_load(\"guard:\\n  mode: off\\n\") => #{YAML.safe_load("guard:\n  mode: off\n").inspect}"
Dir.mktmpdir("sf-yaml-off-") do |dir|
  policy = File.join(dir, ".ai", "policies", "enforcement.yml")
  override = File.join(dir, ".soft-foundry", "enforcement.yml")
  FileUtils.mkdir_p(File.dirname(policy))
  FileUtils.mkdir_p(File.dirname(override))
  [["policy unquoted off", policy, "guard:\n  mode: off\n", nil],
   ["policy quoted \"off\"", policy, "guard:\n  mode: \"off\"\n", nil],
   ["policy warn, override unquoted off", policy, "guard:\n  mode: warn\n", "guard:\n  mode: off\n"],
   ["policy block, override unquoted off", policy, "guard:\n  mode: block\n", "guard:\n  mode: off\n"],
   ["policy block, override quoted \"off\"", policy, "guard:\n  mode: block\n", "guard:\n  mode: \"off\"\n"],
   ["policy block, override unquoted on (not a mode)", policy, "guard:\n  mode: block\n", "guard:\n  mode: on\n"]].each do |label, path, text, override_text|
    File.write(path, text)
    if override_text then File.write(override, override_text) else FileUtils.rm_f(override) end
    puts "#{label.ljust(44)} => #{SoftFoundry::Guard.mode(dir, env: {}).inspect}"
  end
  File.write(policy, "guard:\n  mode: block\n")
  FileUtils.rm_f(override)
  puts "#{'policy block, SOFT_FOUNDRY_GUARD=off'.ljust(44)} => #{SoftFoundry::Guard.mode(dir, env: { 'SOFT_FOUNDRY_GUARD' => 'off' }).inspect}"
end
