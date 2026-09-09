# frozen_string_literal: true

require_relative "errors"

module SoftFoundry
  # Vendor-facing pointer files. Soft Foundry owns only the block between its
  # markers; the rest of the file belongs to the repository and is never
  # rewritten. A marker without the full canonical block is a conflict.
  class AgentFiles
    BEGIN_MARKER = "<!-- soft-foundry:begin -->"
    END_MARKER = "<!-- soft-foundry:end -->"
    # Written by 0.1.0; recognized so existing repositories do not conflict.
    LEGACY_CLAUDE_MARKER = "<!-- soft-foundry:canonical-agent-reference -->"
    CLAUDE_INTERIOR = <<~MARKDOWN.strip
      ## Soft Foundry

      This repository uses Soft Foundry. Before performing engineering work, read and follow `AGENTS.md` and the workflow under `.ai/`. Those files are canonical; do not duplicate or override their engineering policy here.
    MARKDOWN
    LEGACY_CLAUDE_BLOCK = "\n#{LEGACY_CLAUDE_MARKER}\n#{CLAUDE_INTERIOR}\n"

    Plan = Data.define(:path, :status, :reason, :bytes)

    def initialize(root, agents_interior:)
      @root = File.expand_path(root)
      @agents_interior = agents_interior
    end

    def plan_agents = plan_file("AGENTS.md", "# Agent Instructions\n", @agents_interior)
    def plan_claude = plan_file("CLAUDE.md", "# Claude Code Instructions\n", CLAUDE_INTERIOR)

    private

    def plan_file(name, title, interior)
      path = File.join(@root, name)
      raise TargetError, "#{name} is a symlink; init does not write through symlinks" if File.symlink?(path)
      raise TargetError, "#{name} is not a regular file" if File.exist?(path) && !File.file?(path)

      block = "\n#{BEGIN_MARKER}\n#{interior}\n#{END_MARKER}\n"
      return Plan.new(path: name, status: "created", reason: "", bytes: title + block) unless File.exist?(path)

      body = File.binread(path)
      return Plan.new(path: name, status: "skipped", reason: "block present", bytes: body) if body.include?(block)
      return Plan.new(path: name, status: "skipped", reason: "legacy block present", bytes: body) if name == "CLAUDE.md" && body.include?(LEGACY_CLAUDE_BLOCK)
      if [BEGIN_MARKER, END_MARKER, LEGACY_CLAUDE_MARKER].any? { |m| body.include?(m) }
        return Plan.new(path: name, status: "conflict", reason: "marker present without the canonical block", bytes: body)
      end

      separator = body.empty? || body.end_with?("\n") ? "" : "\n"
      Plan.new(path: name, status: "updated", reason: "block appended", bytes: body + separator + block)
    end
  end
end
