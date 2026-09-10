# frozen_string_literal: true

require "json"
require "net/http"
require "open3"
require "uri"
require_relative "version"

module SoftFoundry
  # Checks RubyGems for a newer soft_foundry release and, only when asked,
  # installs it. Checking is always safe and side-effect free; installing
  # requires the caller to explicitly opt in (see `soft-foundry update
  # --yes`). This tool has no interactive prompts anywhere, so "confirm
  # before touching anything" means a second explicit invocation, the same
  # idiom --force and --dry-run already use elsewhere in this CLI.
  class Updater
    Result = Data.define(:current, :latest, :update_available, :error)
    InstallResult = Data.define(:ok, :message)

    LATEST_URI = URI("https://rubygems.org/api/v1/versions/soft_foundry/latest.json")

    def initialize(current: SoftFoundry::VERSION, fetcher: nil, installer: nil)
      @current = current
      @fetcher = fetcher || method(:real_fetch)
      @installer = installer || method(:real_install)
    end

    def check
      latest, error = @fetcher.call
      return Result.new(current: @current, latest: nil, update_available: false, error:) if error
      Result.new(current: @current, latest:, update_available: newer?(latest, @current), error: nil)
    end

    def install!(version)
      @installer.call(version)
    end

    private

    def newer?(latest, current)
      Gem::Version.new(latest) > Gem::Version.new(current)
    rescue ArgumentError
      false
    end

    def real_fetch
      response = Net::HTTP.start(LATEST_URI.host, LATEST_URI.port, use_ssl: true, read_timeout: 10, open_timeout: 5) do |http|
        http.get(LATEST_URI)
      end
      return [nil, "soft_foundry is not published to RubyGems yet"] if response.code == "404"
      return [nil, "HTTP #{response.code}"] unless response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      version = data["version"]
      # RubyGems' own sentinel for a gem with no published version: HTTP 200,
      # not 404, with this literal string in the body.
      return [nil, "soft_foundry is not published to RubyGems yet"] if version == "unknown"
      version ? [version, nil] : [nil, "unexpected response from RubyGems"]
    rescue StandardError => e
      [nil, e.message]
    end

    # Argv-only invocation (no shell interpolation); `version` comes from
    # RubyGems' own JSON response, not user or repository input.
    def real_install(version)
      out, status = Open3.capture2e("gem", "install", "soft_foundry", "-v", version)
      InstallResult.new(ok: status.success?, message: out)
    rescue StandardError => e
      InstallResult.new(ok: false, message: "#{e.class}: #{e.message}")
    end
  end
end
