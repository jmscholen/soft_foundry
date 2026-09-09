# frozen_string_literal: true

require "fileutils"

module SoftFoundry
  # Installs a git pre-commit hook that runs `soft-foundry ci`.
  class Hooks
    MARKER = "# soft-foundry:pre-commit"
    SCRIPT = <<~SH
      #!/bin/sh
      #{MARKER}
      # Validates the .ai/ control plane and every change record before commit.
      if command -v soft-foundry >/dev/null 2>&1; then
        exec soft-foundry ci
      elif [ -x exe/soft-foundry ]; then
        exec ruby -Ilib exe/soft-foundry ci
      else
        echo "soft-foundry not found; skipping control-plane checks" >&2
      fi
    SH

    def self.install(root)
      hooks_dir = File.join(root, ".git", "hooks")
      raise "#{root} is not a git repository" unless File.directory?(File.join(root, ".git"))
      FileUtils.mkdir_p(hooks_dir)
      path = File.join(hooks_dir, "pre-commit")
      if File.exist?(path) && !File.read(path).include?(MARKER)
        raise "#{path} already exists and was not installed by soft-foundry; merge `soft-foundry ci` into it manually"
      end
      File.write(path, SCRIPT)
      File.chmod(0o755, path)
      path
    end
  end
end
