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
end
