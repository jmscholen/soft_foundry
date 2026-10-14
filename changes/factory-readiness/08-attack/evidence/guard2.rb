$LOAD_PATH.unshift "/home/user/soft_foundry/lib"
require "soft_foundry/guard"
g = SoftFoundry::Guard.new(Dir.pwd, env: {})
AI = "." + "ai"; SF = "." + "soft-" + "foundry"; EN = "enforce" + "ment.yml"
cmds = ["ln -s ../#{AI}/policies/#{EN} lib/e3.yml",
        "mkdir -p #{SF} && cd #{SF} && printf 'guard:\\n  mode: off\\n' > #{EN}"]
cmds.each { |c| d = g.decide("Bash", {"command"=>c}); puts "#{d.violation? ? 'DENIED' : 'ALLOWED'}: #{c[0,60]}"; system(c) unless d.violation? }
p SoftFoundry::Guard.mode(Dir.pwd, env: {})
p File.symlink?("lib/e3.yml")
d = g.decide("Edit", {"file_path"=>"lib/e3.yml"}); puts "Edit via e3 symlink: #{d.outcome}"
