# frozen_string_literal: true

module SoftFoundry
  class Shell
    COMMANDS = {
      "claude" => "claude",
      "codex" => "codex",
      "grok" => "grok"
    }.freeze

    # The executable for a named shell on PATH, or raises.
    def self.resolve(name)
      command = COMMANDS.fetch(name) { raise ArgumentError, "Unknown shell '#{name}'. Supported: #{COMMANDS.keys.join(', ')}" }
      executable = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, command) }.find { |path| File.executable?(path) && !File.directory?(path) }
      raise "#{command} is not installed or not on PATH" unless executable
      executable
    end

    def self.launch(name, args = [])
      exec(resolve(name), *args)
    end
  end
end
