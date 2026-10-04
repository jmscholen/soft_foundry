# frozen_string_literal: true

require "json"
require "net/http"
require "open3"
require "rbconfig"
require "tmpdir"
require "uri"
require_relative "version"

module SoftFoundry
  # Checks the GitHub repository for a newer soft_foundry release and, only
  # when asked, installs it. The gem is not published to RubyGems: a release
  # is a tag on github.com/jmscholen/soft_foundry, with the built gem
  # attached by the release workflow, or failing that the tagged source,
  # which is built here. Checking is always safe and side-effect free;
  # installing requires the caller to explicitly opt in (see `soft-foundry
  # update --yes`). This tool has no interactive prompts anywhere, so
  # "confirm before touching anything" means a second explicit invocation,
  # the same idiom --force and --dry-run already use elsewhere in this CLI.
  #
  # The install goes under the Ruby running this command, which is the one
  # the `soft-foundry` on PATH uses, whatever repository it is run from.
  class Updater
    Result = Data.define(:current, :latest, :update_available, :error)
    InstallResult = Data.define(:ok, :message)
    Release = Data.define(:version, :gem_url, :gem_name, :tarball_url)

    REPOSITORY = "jmscholen/soft_foundry"
    LATEST_URI = URI("https://api.github.com/repos/#{REPOSITORY}/releases/latest")
    GEM_NAME = /\Asoft_foundry-(\d+\.\d+\.\d+)\.gem\z/
    VERSION_TAG = /\Av?(\d+\.\d+\.\d+)\z/

    # The `gem` of the Ruby running this command, by path: `ruby -S gem`
    # finds whatever `gem` is first on PATH, which under a version manager
    # is a shim for another Ruby (found by the first real release).
    def self.gem_command = [RbConfig.ruby, File.join(RbConfig::CONFIG["bindir"], "gem")]

    def initialize(current: SoftFoundry::VERSION, fetcher: nil, installer: nil, http: nil, release: nil, downloader: nil, runner: nil)
      @current = current
      @http = http || method(:real_http)
      @fetcher = fetcher || method(:real_fetch)
      @installer = installer || method(:real_install)
      @release = release
      @downloader = downloader || method(:real_download)
      @runner = runner || method(:real_run)
    end

    def check
      latest, error = @fetcher.call
      return Result.new(current: @current, latest: nil, update_available: false, error:) if error
      Result.new(current: @current, latest:, update_available: newer?(latest, @current), error: nil)
    end

    def install!(version)
      @installer.call(version)
    end

    # The release GitHub describes, or why it is not one: the tag is the
    # version, and the gem attached to it (if any) and the tagged source
    # are where it comes from.
    def self.parse_release(body)
      data = JSON.parse(body)
      return [nil, "unexpected response from GitHub"] unless data.is_a?(Hash)
      tag = data["tag_name"].to_s
      match = VERSION_TAG.match(tag) or return [nil, "the latest release is tagged '#{tag}', which is not a version"]
      asset = Array(data["assets"]).find { |a| a.is_a?(Hash) && a["name"].to_s.match?(GEM_NAME) }
      [Release.new(version: match[1], gem_url: asset && asset["browser_download_url"].to_s, gem_name: asset && asset["name"].to_s,
                   tarball_url: data["tarball_url"]&.to_s), nil]
    rescue JSON::ParserError
      [nil, "unexpected response from GitHub"]
    end

    private

    def newer?(latest, current)
      Gem::Version.new(latest) > Gem::Version.new(current)
    rescue ArgumentError
      false
    end

    def headers
      h = { "Accept" => "application/vnd.github+json", "User-Agent" => "soft-foundry/#{SoftFoundry::VERSION}" }
      token = ENV["GITHUB_TOKEN"].to_s
      h["Authorization"] = "Bearer #{token}" unless token.empty?
      h
    end

    def real_http(uri, request_headers)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 10, open_timeout: 5) do |http|
        http.get(uri.request_uri, request_headers)
      end
    end

    def real_fetch
      response = @http.call(LATEST_URI, headers)
      return [nil, "no release has been published on GitHub yet (https://github.com/#{REPOSITORY}/releases)"] if response.code == "404"
      return [nil, "HTTP #{response.code} from GitHub"] unless response.is_a?(Net::HTTPSuccess)
      release, error = self.class.parse_release(response.body)
      return [nil, error] if error
      @release = release
      [release.version, nil]
    rescue StandardError => e
      [nil, e.message]
    end

    # Installs exactly the release that was found: its attached gem, or the
    # gem built from its source. Everything runs as an argument list, never
    # through a shell. The gem is saved under the name the release lists for
    # it (a download's final address is not a name: GitHub's is a UUID),
    # and that name must be soft_foundry-<version>.gem for this version.
    def real_install(version)
      release = @release || begin
        latest, error = real_fetch
        return InstallResult.new(ok: false, message: error) if error
        @release if latest
      end
      return InstallResult.new(ok: false, message: "the release found is #{release.version}, not #{version}; run `soft-foundry update` again") unless release.version == version
      Dir.mktmpdir("soft-foundry-update") do |dir|
        gem = if release.gem_url
                @downloader.call(release.gem_url, dir, File.basename(release.gem_name.to_s))
              elsif release.tarball_url
                build_from_source(release, dir) or return InstallResult.new(ok: false, message: "could not build soft_foundry #{version} from the release's source")
              else
                return InstallResult.new(ok: false, message: "release #{version} has neither a gem attached nor source to build from")
              end
        name = File.basename(gem)
        unless (m = GEM_NAME.match(name)) && m[1] == version
          return InstallResult.new(ok: false, message: "the release's file is named #{name}, not soft_foundry-#{version}.gem; not installing it")
        end
        out, ok = @runner.call([*self.class.gem_command, "install", "--local", gem], dir)
        InstallResult.new(ok: ok, message: out)
      end
    rescue StandardError => e
      InstallResult.new(ok: false, message: "#{e.class}: #{e.message}")
    end

    # The tagged source, built with the same Ruby: the path of the gem it
    # produced, or nil.
    def build_from_source(release, dir)
      tarball = @downloader.call(release.tarball_url, dir, "source.tar.gz")
      extracted = File.join(dir, "source")
      Dir.mkdir(extracted)
      _, ok = @runner.call(["tar", "-xzf", tarball, "-C", extracted], dir)
      return nil unless ok
      root = Dir.children(extracted).map { |c| File.join(extracted, c) }.find { |c| File.file?(File.join(c, "soft_foundry.gemspec")) }
      return nil unless root
      _, built = @runner.call([*self.class.gem_command, "build", "soft_foundry.gemspec"], root)
      return nil unless built
      Dir.children(root).map { |c| File.join(root, c) }.find { |c| File.basename(c).match?(GEM_NAME) }
    end

    # Follows GitHub's redirects to its download host and saves the body
    # under the name the caller chose.
    def real_download(url, dir, name, hops = 0)
      uri = URI(url)
      raise "#{url} is not an https address" unless uri.scheme == "https"
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 60, open_timeout: 5) do |http|
        http.get(uri.request_uri, headers.reject { |k, _| k == "Authorization" && !uri.host.end_with?("github.com") })
      end
      if response.is_a?(Net::HTTPRedirection) && hops < 5
        return real_download(response["location"], dir, name, hops + 1)
      end
      raise "HTTP #{response.code} downloading #{url}" unless response.is_a?(Net::HTTPSuccess)
      path = File.join(dir, name)
      File.binwrite(path, response.body)
      path
    end

    def real_run(argv, chdir)
      out, status = Open3.capture2e(*argv, chdir: chdir)
      [out, status.success?]
    end
  end
end
