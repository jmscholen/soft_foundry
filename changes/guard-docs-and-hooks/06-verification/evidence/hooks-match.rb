# Verification evidence script (CHECK-006). Read-only against the repository:
# installs the guard hooks into a throwaway directory with the library's own
# installer and compares the result with what this repository has committed.
# Nothing under the repository is written. Run as:
#   bundle exec ruby -Ilib changes/guard-docs-and-hooks/06-verification/evidence/hooks-match.rb .
require "json"
require "tmpdir"
require "soft_foundry"

root = File.expand_path(ARGV.fetch(0))
status = 0
Dir.mktmpdir("sf-hooks-") do |dir|
  SoftFoundry::Hooks.install_claude(dir)
  SoftFoundry::Hooks.install_codex(dir)
  [SoftFoundry::Hooks.claude_settings_path(dir), SoftFoundry::Hooks.codex_hooks_path(dir)].each do |fresh|
    rel = fresh.delete_prefix(dir + "/")
    committed = File.join(root, rel)
    a = JSON.parse(File.read(fresh))
    b = JSON.parse(File.read(committed))
    same = a == b
    status = 1 unless same
    puts "#{rel}: #{same ? 'matches' : 'DIFFERS FROM'} a fresh `soft-foundry hooks install`"
    b.fetch("hooks").each do |event, entries|
      entries.each do |e|
        puts "  #{event} matcher=#{e['matcher']} command=#{e.dig('hooks', 0, 'command').lines.first.strip}"
      end
    end
    unless same
      puts "  fresh:     #{JSON.generate(a)}"
      puts "  committed: #{JSON.generate(b)}"
    end
  end
end
puts "GUARD_MATCHER=#{SoftFoundry::Hooks::GUARD_MATCHER}"
puts "CODEX_GUARD_MATCHER=#{SoftFoundry::Hooks::CODEX_GUARD_MATCHER}"
puts "claude_installed? #{SoftFoundry::Hooks.claude_installed?(root).inspect}"
puts "codex_installed? #{SoftFoundry::Hooks.codex_installed?(root).inspect}"
exit status
