# frozen_string_literal: true

require_relative "errors"
require_relative "providers"

module SoftFoundry
  # Which way model usage is paid for on this machine. A subscription (a
  # coding shell logged in to a Pro/Max/Team-style plan) is a flat fee with
  # nothing metered per token, so no dollar budget applies. An API key bills
  # per token, so the budget policy in .ai/policies/budget.yml applies.
  #
  # Detection is a heuristic over the environment, never repository policy:
  # billing is a fact about the person running the tool, not about the
  # repository. SOFT_FOUNDRY_BILLING=api|subscription overrides it.
  class Billing
    Mode = Data.define(:mode, :reason) do
      def api? = mode == "api"
      def subscription? = mode == "subscription"
    end

    MODES = %w[api subscription].freeze
    OVERRIDE_ENV = "SOFT_FOUNDRY_BILLING"

    # Environment variables that switch each coding shell from its own login
    # (subscription) to metered billing. Claude Code also honors an auth
    # token and the Bedrock/Vertex switches, all of which are metered.
    SHELL_KEYS = {
      "claude" => %w[ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX],
      "codex" => %w[OPENAI_API_KEY],
      "grok" => %w[XAI_API_KEY]
    }.freeze

    # shell: nil considers every provider key Soft Foundry knows about (the
    # right question for a generic command); a shell name considers only the
    # variables that shell itself reads, since an unrelated provider's key in
    # the environment does not change how that shell bills.
    def self.detect(shell: nil, env: ENV)
      override = env[OVERRIDE_ENV].to_s.strip
      unless override.empty?
        raise TargetError, "#{OVERRIDE_ENV}=#{override} is not one of #{MODES.join(', ')}" unless MODES.include?(override)
        return Mode.new(mode: override, reason: "#{OVERRIDE_ENV}=#{override}")
      end

      keys = shell ? SHELL_KEYS.fetch(shell) { raise ArgumentError, "unknown shell '#{shell}'" } : Providers.all.map(&:api_key_env)
      present = keys.select { |k| !env[k].to_s.empty? }
      if present.empty?
        reason = shell ? "no #{keys.first} in the environment, so #{shell} bills to its own login" : "no provider API key (#{keys.join(', ')}) in the environment"
        Mode.new(mode: "subscription", reason:)
      else
        Mode.new(mode: "api", reason: "#{present.join(', ')} set, so usage is metered per token")
      end
    end
  end
end
