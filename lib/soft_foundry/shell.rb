# frozen_string_literal: true

module SoftFoundry
  class Shell
    COMMANDS = {
      "claude" => "claude",
      "codex" => "codex",
      "grok" => "grok"
    }.freeze

    def self.launch(name, args = [])
      command = COMMANDS.fetch(name) { raise ArgumentError, "Unknown shell '#{name}'. Supported: #{COMMANDS.keys.join(', ')}" }
      executable = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, command) }.find { |path| File.executable?(path) && !File.directory?(path) }
      raise "#{command} is not installed or not on PATH" unless executable

      exec(executable, *args)
    end
  end
end
