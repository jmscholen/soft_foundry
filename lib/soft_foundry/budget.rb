# frozen_string_literal: true

require "time"
require "yaml"
require_relative "errors"
require_relative "safe_write"

module SoftFoundry
  # Reads .ai/policies/budget.yml (policy) and changes/<slug>/budget.yml (the
  # recorded ledger) and compares one against the other. Nothing here meters
  # a real API call; entries are recorded by whoever executed a phase.
  class Budget
    Entry = Data.define(:phase, :provider, :model, :tokens_in, :tokens_out, :estimated_usd, :recorded_at, :recorded_by)
    Totals = Data.define(:tokens_in, :tokens_out, :estimated_usd, :entries_missing_cost)
    Policy = Data.define(:max_usd_per_phase, :max_usd_per_change, :require_human_approval_above_usd)

    def initialize(record)
      @record = record
    end

    def path = File.join(@record.dir, "budget.yml")

    def entries
      return [] unless File.exist?(path)
      data = YAML.safe_load_file(path, aliases: false) || {}
      Array(data["entries"]).map do |e|
        Entry.new(phase: e["phase"], provider: e["provider"], model: e["model"],
                  tokens_in: e["tokens_in"].to_i, tokens_out: e["tokens_out"].to_i,
                  estimated_usd: e["estimated_usd"]&.to_f, recorded_at: e["recorded_at"], recorded_by: e["recorded_by"])
      end
    end

    def record!(phase:, provider:, model:, tokens_in:, tokens_out:, estimated_usd: nil, recorded_by: ENV["USER"] || "unknown", now: Time.now)
      data = File.exist?(path) ? YAML.safe_load_file(path, aliases: false) : { "change" => @record.slug, "entries" => [] }
      data["entries"] ||= []
      data["entries"] << {
        "phase" => phase, "provider" => provider, "model" => model,
        "tokens_in" => tokens_in, "tokens_out" => tokens_out, "estimated_usd" => estimated_usd,
        "recorded_at" => now.utc.iso8601, "recorded_by" => recorded_by
      }
      SafeWrite.write(path, YAML.dump(data))
    end

    def totals
      list = entries
      known = list.filter_map(&:estimated_usd)
      Totals.new(
        tokens_in: list.sum(&:tokens_in), tokens_out: list.sum(&:tokens_out),
        estimated_usd: known.empty? ? nil : known.sum,
        entries_missing_cost: list.count { |e| e.estimated_usd.nil? }
      )
    end

    def self.policy(control_plane, risk: nil)
      data = YAML.safe_load_file(File.join(control_plane.dir, "policies", "budget.yml"))
      base = data.fetch("defaults", {})
      override = data.fetch("overrides_by_risk", {})[risk.to_s] || {}
      merged = base.merge(override)
      Policy.new(max_usd_per_phase: merged["max_usd_per_phase"]&.to_f, max_usd_per_change: merged["max_usd_per_change"]&.to_f,
                 require_human_approval_above_usd: merged["require_human_approval_above_usd"]&.to_f)
    end

    # true when spend is known to exceed the cap; false when under or unknown.
    def over_cap?(policy)
      usd = totals.estimated_usd
      !usd.nil? && !policy.max_usd_per_change.nil? && usd > policy.max_usd_per_change
    end
  end
end
