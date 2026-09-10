# frozen_string_literal: true

require "time"
require "yaml"

module SoftFoundry
  # Renders the capability findings already recorded in .ai/repository.yml
  # into something a person actually reads: a short terminal summary and a
  # persisted markdown report. Pure presentation over data scan/deep mode
  # already produced; no new assessment logic.
  class MaturityReport
    SATISFIED = %w[PASS EXTERNAL NOT_APPLICABLE].freeze

    def self.from_file(path)
      new(YAML.safe_load_file(path, permitted_classes: [Time, Date]) || {})
    end

    def initialize(data)
      @data = data
    end

    def assessed? = !!repository["assessed"]
    def repository = @data["repository"] || {}
    def maturity = @data["maturity"] || {}
    def capabilities = @data["capabilities"] || {}
    def current_level = maturity["current_level"]
    def current_id = maturity["current_id"]
    def gaps = Array(maturity["gaps"])

    # Non-satisfied capabilities not already named as blocking the next
    # level: real, recorded findings (e.g. a conditional observability
    # sub-signal, or a requirement of a level further out) that don't gate
    # the current score but are worth surfacing.
    def other_deficiencies
      blocking = gaps.map { |g| g["capability"] }
      capabilities.reject { |cap, entry| SATISFIED.include?(entry["status"]) || blocking.include?(cap) }
    end

    def satisfied_count = capabilities.count { |_, e| SATISFIED.include?(e["status"]) }

    def summary_lines
      return ["maturity: not yet assessed. Run `soft-foundry onboard --maturity=scan` (or `deep`)."] unless assessed?

      lines = ["maturity: level #{current_level} (#{current_id}) — #{satisfied_count}/#{capabilities.size} capabilities satisfied"]
      if gaps.empty?
        lines << "  nothing currently blocks the next level"
      else
        lines << "  blocking the next level:"
        gaps.each { |g| lines << "    - #{g['capability']} (#{g['status']})" }
      end
      unless other_deficiencies.empty?
        word = other_deficiencies.size == 1 ? "deficiency" : "deficiencies"
        lines << "  #{other_deficiencies.size} other recorded #{word} not yet blocking a level, see the report"
      end
      lines << "  full report: .ai/maturity-report.md"
      lines
    end

    def to_markdown
      return unassessed_markdown unless assessed?

      lines = []
      lines << "# Maturity Report"
      lines << ""
      lines << "Generated from `.ai/repository.yml`, assessed #{repository['assessed_at']} by #{repository['assessed_by']} at commit `#{repository['commit_sha']}`. Regenerated on every `soft-foundry onboard`/`init` run; edits here are not preserved."
      lines << ""
      lines << "**Level #{current_level} (#{current_id})** — #{satisfied_count} of #{capabilities.size} recorded capabilities satisfied."
      lines << ""
      lines << "## Blocking the next level"
      lines << ""
      if gaps.empty?
        lines << "Nothing currently blocks the next level."
      else
        gaps.each { |g| lines.concat(capability_section(g["capability"])) }
      end
      unless other_deficiencies.empty?
        lines << "## Other recorded deficiencies"
        lines << ""
        lines << "Not required for the next level yet (a conditional signal, or a requirement of a level further out), but real, evidence-backed findings worth planning for."
        lines << ""
        other_deficiencies.each_key { |cap| lines.concat(capability_section(cap)) }
      end
      "#{lines.join("\n")}\n"
    end

    private

    def capability_section(cap)
      entry = capabilities[cap] || {}
      lines = ["### `#{cap}` — #{entry['status']}", ""]
      lines << (entry["rationale"] || "No rationale recorded.")
      lines << ""
      lines << "Findings: #{Array(entry['findings']).join(', ')}" unless Array(entry["findings"]).empty?
      lines << "Evidence: #{Array(entry['evidence']).join(', ')}" unless Array(entry["evidence"]).empty?
      lines << ""
      lines
    end

    def unassessed_markdown
      "# Maturity Report\n\nThis repository has not been assessed. Run `soft-foundry onboard --maturity=scan` (free, deterministic) or `--maturity=deep` (agentic, costs tokens/subscription usage).\n"
    end
  end
end
