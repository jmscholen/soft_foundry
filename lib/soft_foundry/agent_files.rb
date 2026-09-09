# frozen_string_literal: true

module SoftFoundry
  class AgentFiles
    CLAUDE_MARKER = "<!-- soft-foundry:canonical-agent-reference -->"
    CLAUDE_BLOCK = <<~MARKDOWN.freeze

      #{CLAUDE_MARKER}
      ## Soft Foundry

      This repository uses Soft Foundry. Before performing engineering work, read and follow `AGENTS.md` and the workflow under `.ai/`. Those files are canonical; do not duplicate or override their engineering policy here.
    MARKDOWN

    def initialize(root = Dir.pwd)
      @root = File.expand_path(root)
    end

    def ensure_agents!
      path = File.join(@root, "AGENTS.md")
      return :present if File.exist?(path)

      File.write(path, <<~MARKDOWN)
        # Agent Instructions

        This repository uses Soft Foundry.

        1. Read `.ai/README.md`.
        2. Load `.ai/workflow.yml`.
        3. Determine the active change and lifecycle phase.
        4. Load the assigned skill's `SKILL.md`, `skill.yml`, `permissions.yml`, `requirements.yml`, and `completion.yml`.
        5. Never skip required gates or modify another skill's evidence.
        6. Never declare completion without final judgment.
      MARKDOWN
      :created
    end

    def ensure_claude!
      path = File.join(@root, "CLAUDE.md")
      if File.exist?(path)
        body = File.read(path)
        return :present if body.include?(CLAUDE_MARKER)
        File.open(path, "a") { |f| f.write(CLAUDE_BLOCK) }
        :updated
      else
        File.write(path, "# Claude Code Instructions\n#{CLAUDE_BLOCK}")
        :created
      end
    end
  end
end
