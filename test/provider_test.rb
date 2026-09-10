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

class ProviderTruncationTest < Minitest::Test
  def test_sanitize_truncates_long_values # ATTACK-019
    long = "a" * 5000
    assert_equal 203, SoftFoundry::Provider.sanitize(long).length
  end
end

class OpenRouterProviderTest < Minitest::Test
  def test_openrouter_is_in_the_provider_list
    provider = SoftFoundry::Providers.all.find { |p| p.name == "openrouter" }
    refute_nil provider
    assert_equal "OPENROUTER_API_KEY", provider.api_key_env
    result = provider.discover(env: {})
    refute result.configured
  end

  def test_openrouter_uses_default_bearer_auth
    provider = SoftFoundry::Provider.new(name: "openrouter", api_key_env: "OPENROUTER_API_KEY", models_uri: "https://openrouter.ai/api/v1/models")
    assert_equal({ "Authorization" => "Bearer xyz" }, provider.send(:authorization_headers, "xyz"))
  end
end
