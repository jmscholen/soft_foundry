# frozen_string_literal: true

require_relative "lib/soft_foundry/version"

Gem::Specification.new do |spec|
  spec.name = "soft_foundry"
  spec.version = SoftFoundry::VERSION
  spec.authors = ["Jeff Scholen"]
  spec.summary = "Repository-native control plane for autonomous software engineering"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*", "exe/*", "README.md", "AGENTS.md", ".ai/**/*", "changes/README.md", "docs/user/README.md"]
  spec.bindir = "exe"
  spec.executables = ["soft-foundry"]
  spec.require_paths = ["lib"]
  spec.metadata["source_code_uri"] = "https://github.com/jmscholen/soft_foundry"
end
