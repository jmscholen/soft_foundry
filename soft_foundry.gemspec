# frozen_string_literal: true

require_relative "lib/soft_foundry/version"

Gem::Specification.new do |spec|
  spec.name = "soft_foundry"
  spec.version = SoftFoundry::VERSION
  spec.authors = ["Jeff Scholen"]
  spec.summary = "Repository-native control plane for autonomous software engineering"
  spec.description = "Commit a lifecycle next to the code. Agents follow declared skills; the CLI checks evidence, permissions, and staleness."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir[
    "lib/**/*",
    "exe/*",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "AGENTS.md",
    ".ai/**/*",
    "changes/README.md",
    "docs/user/README.md",
    "docs/contributing.md",
    "examples/tiny-app/**/*"
  ]
  spec.bindir = "exe"
  spec.executables = ["soft-foundry"]
  spec.require_paths = ["lib"]
  spec.metadata["source_code_uri"] = "https://github.com/jmscholen/soft_foundry"
  spec.metadata["bug_tracker_uri"] = "https://github.com/jmscholen/soft_foundry/issues"
  spec.homepage = "https://github.com/jmscholen/soft_foundry"
end
