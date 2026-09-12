# frozen_string_literal: true

require_relative "test_helper"

class BillingTest < Minitest::Test
  ALL_KEYS = %w[ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX OPENAI_API_KEY XAI_API_KEY OPENROUTER_API_KEY SOFT_FOUNDRY_BILLING].freeze

  def env(overrides = {})
    ALL_KEYS.to_h { |k| [k, nil] }.merge(overrides)
  end

  def test_no_keys_anywhere_is_a_subscription
    mode = SoftFoundry::Billing.detect(env: env)
    assert mode.subscription?
    assert_includes mode.reason, "no provider API key"
  end

  def test_any_provider_key_means_metered_for_a_generic_command
    mode = SoftFoundry::Billing.detect(env: env("OPENROUTER_API_KEY" => "k"))
    assert mode.api?
    assert_includes mode.reason, "OPENROUTER_API_KEY"
  end

  def test_a_shell_only_looks_at_its_own_variables
    # An OpenAI key does not change how Claude Code bills.
    claude = SoftFoundry::Billing.detect(shell: "claude", env: env("OPENAI_API_KEY" => "k"))
    assert claude.subscription?
    assert_includes claude.reason, "claude bills to its own login"

    codex = SoftFoundry::Billing.detect(shell: "codex", env: env("OPENAI_API_KEY" => "k"))
    assert codex.api?
  end

  def test_claude_treats_auth_token_and_bedrock_as_metered
    assert SoftFoundry::Billing.detect(shell: "claude", env: env("ANTHROPIC_AUTH_TOKEN" => "t")).api?
    assert SoftFoundry::Billing.detect(shell: "claude", env: env("CLAUDE_CODE_USE_BEDROCK" => "1")).api?
    assert SoftFoundry::Billing.detect(shell: "claude", env: env("ANTHROPIC_API_KEY" => "")).subscription?
  end

  def test_override_wins_in_both_directions
    forced_sub = SoftFoundry::Billing.detect(env: env("ANTHROPIC_API_KEY" => "k", "SOFT_FOUNDRY_BILLING" => "subscription"))
    assert forced_sub.subscription?
    assert_includes forced_sub.reason, "SOFT_FOUNDRY_BILLING=subscription"
    forced_api = SoftFoundry::Billing.detect(shell: "claude", env: env("SOFT_FOUNDRY_BILLING" => "api"))
    assert forced_api.api?
  end

  def test_bad_override_is_a_target_error
    e = assert_raises(SoftFoundry::TargetError) { SoftFoundry::Billing.detect(env: env("SOFT_FOUNDRY_BILLING" => "maybe")) }
    assert_includes e.message, "api, subscription"
  end

  def test_unknown_shell_is_rejected
    assert_raises(ArgumentError) { SoftFoundry::Billing.detect(shell: "vim", env: env) }
  end
end
