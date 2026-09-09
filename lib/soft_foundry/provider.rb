# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module SoftFoundry
  class Provider
    Result = Data.define(:name, :configured, :models, :error)

    attr_reader :name, :api_key_env, :models_uri, :headers

    def initialize(name:, api_key_env:, models_uri:, headers: {})
      @name = name
      @api_key_env = api_key_env
      @models_uri = URI(models_uri)
      @headers = headers
    end

    def discover(env: ENV)
      key = env[api_key_env]
      return Result.new(name:, configured: false, models: [], error: nil) if key.nil? || key.empty?

      request = Net::HTTP::Get.new(models_uri)
      authorization_headers(key).merge(headers).each { |k, v| request[k] = v }
      response = Net::HTTP.start(models_uri.host, models_uri.port, use_ssl: models_uri.scheme == "https", read_timeout: 10, open_timeout: 5) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        return Result.new(name:, configured: true, models: [], error: "HTTP #{response.code}")
      end

      payload = JSON.parse(response.body)
      models = Array(payload["data"]).filter_map { |entry| self.class.sanitize(entry["id"]) }.reject(&:empty?).sort
      Result.new(name:, configured: true, models:, error: nil)
    rescue StandardError => e
      Result.new(name:, configured: true, models: [], error: e.message)
    end

    # Provider responses are untrusted; keep report lines to printable ASCII.
    def self.sanitize(value)
      value.to_s.gsub(/[^ -~]/, "?")
    end

    private

    def authorization_headers(key)
      { "Authorization" => "Bearer #{key}" }
    end
  end
end
