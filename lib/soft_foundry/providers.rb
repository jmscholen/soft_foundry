# frozen_string_literal: true

require_relative "provider"

module SoftFoundry
  module Providers
    module_function

    def all
      [
        Provider.new(name: "openai", api_key_env: "OPENAI_API_KEY", models_uri: "https://api.openai.com/v1/models"),
        Provider.new(
          name: "anthropic",
          api_key_env: "ANTHROPIC_API_KEY",
          models_uri: "https://api.anthropic.com/v1/models",
          headers: { "anthropic-version" => "2023-06-01" }
        ).tap do |provider|
          def provider.authorization_headers(key)
            { "x-api-key" => key }
          end
        end,
        Provider.new(name: "xai", api_key_env: "XAI_API_KEY", models_uri: "https://api.x.ai/v1/models")
      ]
    end
  end
end
