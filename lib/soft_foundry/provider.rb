# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module SoftFoundry
  class Provider
    Result = Data.define(:name, :configured, :models, :error, :api_key_env)

    attr_reader :name, :api_key_env, :models_uri, :headers

    def initialize(name:, api_key_env:, models_uri:, headers: {})
      @name = name
      @api_key_env = api_key_env
      @models_uri = URI(models_uri)
      @headers = headers
    end

    def discover(env: ENV)
      key = env[api_key_env]
      return Result.new(name:, configured: false, models: [], error: nil, api_key_env:) if key.nil? || key.empty?

      request = Net::HTTP::Get.new(models_uri)
      authorization_headers(key).merge(headers).each { |k, v| request[k] = v }
      response = Net::HTTP.start(models_uri.host, models_uri.port, use_ssl: models_uri.scheme == "https", read_timeout: 10, open_timeout: 5) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        return Result.new(name:, configured: true, models: [], error: "HTTP #{self.class.sanitize(response.code)}", api_key_env:)
      end

      payload = JSON.parse(response.body)
      models = Array(payload["data"]).filter_map { |entry| self.class.sanitize(entry["id"]) }.reject(&:empty?).sort
      Result.new(name:, configured: true, models:, error: nil, api_key_env:)
    rescue StandardError => e
      Result.new(name:, configured: true, models: [], error: self.class.sanitize(e.message), api_key_env:)
    end

    MAX_LENGTH = 200

    # Provider responses are untrusted; keep them printable ASCII and bounded.
    def self.sanitize(value)
      text = value.to_s.gsub(/[^ -~]/, "?")
      text.length > MAX_LENGTH ? "#{text[0, MAX_LENGTH]}..." : text
    end

    private

    def authorization_headers(key)
      { "Authorization" => "Bearer #{key}" }
    end
  end
end
