# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/soft_foundry/provider"

class ProviderTest < Minitest::Test
  def test_unconfigured_provider_does_not_make_network_request
    provider = SoftFoundry::Provider.new(name: "xai", api_key_env: "XAI_API_KEY", models_uri: "https://api.x.ai/v1/models")
    result = provider.discover(env: {})

    refute result.configured
    assert_empty result.models
    assert_nil result.error
  end

  def test_model_ids_are_sanitized_to_printable_ascii # MIT-015
    assert_equal "gpt?\e-x".gsub(/[^ -~]/, "?"), SoftFoundry::Provider.sanitize("gpt\n\e-x")
    refute_includes SoftFoundry::Provider.sanitize("a\e[31mb\n"), "\e"
  end
end
