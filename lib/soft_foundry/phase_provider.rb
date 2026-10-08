# frozen_string_literal: true

module SoftFoundry
  # Which provider a lifecycle phase ran on, from its handoff. Kept apart
  # from the runner so the advisory and the gate can ask without loading it.
  module PhaseProvider
    # Which provider each shell runs on, and the names a handoff's
    # resolved_model.provider may use for it.
    SHELLS = { "claude" => "anthropic", "codex" => "openai", "grok" => "xai" }.freeze
    NAMES = {
      "anthropic" => "anthropic", "claude" => "anthropic",
      "openai" => "openai", "codex" => "openai",
      "xai" => "xai", "x.ai" => "xai", "grok" => "xai"
    }.freeze

    module_function

    # The handoff's resolved_model.provider when it is a name this knows,
    # else the shell `phase run` recorded, else nil.
    def of(handoff)
      return nil unless handoff.is_a?(Hash)
      named = handoff.dig("resolved_model", "provider").to_s.strip.downcase
      NAMES[named] || SHELLS[handoff.dig("executed_by", "shell").to_s]
    end

    def of_shell(shell) = SHELLS[shell.to_s]
  end
end
