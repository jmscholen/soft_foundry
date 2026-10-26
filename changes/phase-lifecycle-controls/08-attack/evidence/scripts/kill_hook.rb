# preloaded with RUBYOPT=-r to simulate a kill (SIGKILL-equivalent, no ensure blocks) at the Nth rename of a transaction
require "soft_foundry"
module KillAt
  def commit_staged(tmp, path)
    @n = (@n || 0) + 1
    if @n == Integer(ENV["KILL_AT"])
      $stderr.puts "KILLED before rename ##{@n} (#{File.basename(path)})"
      Process.kill("KILL", Process.pid)
    end
    super
  end
end
SoftFoundry::SafeWrite.singleton_class.prepend(KillAt)
