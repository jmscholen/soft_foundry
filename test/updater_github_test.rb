# frozen_string_literal: true

require "json"
require "rbconfig"
require_relative "test_helper"

# `soft-foundry update` takes the latest release of the GitHub repository,
# not RubyGems: the gem is never published there.
class UpdaterGithubTest < Minitest::Test
  RELEASE = {
    "tag_name" => "v0.17.0", "name" => "0.17.0",
    "tarball_url" => "https://api.github.com/repos/jmscholen/soft_foundry/tarball/v0.17.0",
    "assets" => [
      { "name" => "soft_foundry-0.17.0.gem", "browser_download_url" => "https://github.com/jmscholen/soft_foundry/releases/download/v0.17.0/soft_foundry-0.17.0.gem" },
      { "name" => "notes.txt", "browser_download_url" => "https://github.com/x/notes.txt" }
    ]
  }.freeze

  def test_the_latest_release_names_the_version_the_gem_and_the_source
    release, error = SoftFoundry::Updater.parse_release(JSON.generate(RELEASE))
    assert_nil error
    assert_equal "0.17.0", release.version
    assert_equal RELEASE["assets"][0]["browser_download_url"], release.gem_url
    assert_equal RELEASE["tarball_url"], release.tarball_url
  end

  def test_a_tag_without_a_v_and_a_release_without_a_gem_are_fine
    release, = SoftFoundry::Updater.parse_release(JSON.generate(RELEASE.merge("tag_name" => "0.17.0", "assets" => [])))
    assert_equal "0.17.0", release.version
    assert_nil release.gem_url
    assert_equal RELEASE["tarball_url"], release.tarball_url
  end

  def test_a_release_that_is_not_a_version_is_an_error
    _, error = SoftFoundry::Updater.parse_release(JSON.generate(RELEASE.merge("tag_name" => "latest")))
    assert_includes error, "latest"
    _, error = SoftFoundry::Updater.parse_release("not json")
    assert_includes error, "GitHub"
  end

  def test_the_release_address_is_the_repository_on_github
    assert_equal "https://api.github.com/repos/jmscholen/soft_foundry/releases/latest", SoftFoundry::Updater::LATEST_URI.to_s
  end

  # The real installer, with the network and the shell replaced: it
  # downloads the release's gem and installs it under the Ruby running
  # this command, never through a shell.
  def updater(release, downloads: {}, &runner)
    ran = []
    downloader = lambda do |url, dir|
      body = downloads.fetch(url)
      path = File.join(dir, body[:name])
      File.write(path, body[:bytes] || "gem bytes")
      path
    end
    run = lambda do |argv, chdir|
      ran << [argv, chdir]
      runner ? runner.call(argv, chdir) : ["ok", true]
    end
    u = SoftFoundry::Updater.new(current: "0.16.0", fetcher: -> { [release.version, nil] }, release: release, downloader: downloader, runner: run)
    [u, ran]
  end

  def test_installs_the_gem_attached_to_the_release
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: "https://example.test/soft_foundry-0.17.0.gem", tarball_url: nil)
    u, ran = updater(release, downloads: { release.gem_url => { name: "soft_foundry-0.17.0.gem" } })
    result = u.install!("0.17.0")
    assert result.ok, result.message
    assert_equal 1, ran.size
    argv, = ran.first
    assert_equal [RbConfig.ruby, "-S", "gem", "install", "--local"], argv.first(5)
    assert_match(%r{/soft_foundry-0\.17\.0\.gem\z}, argv.last)
  end

  def test_builds_from_the_source_when_no_gem_is_attached
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: nil, tarball_url: "https://example.test/tarball/v0.17.0")
    u, ran = updater(release, downloads: { release.tarball_url => { name: "source.tar.gz" } }) do |argv, chdir|
      if argv.first == "tar"
        src = File.join(argv[argv.index("-C") + 1], "jmscholen-soft_foundry-abc123")
        FileUtils.mkdir_p(src)
        File.write(File.join(src, "soft_foundry.gemspec"), "")
        ["", true]
      elsif argv.include?("build")
        File.write(File.join(chdir, "soft_foundry-0.17.0.gem"), "built")
        ["Successfully built RubyGem", true]
      else
        ["Successfully installed soft_foundry-0.17.0", true]
      end
    end
    result = u.install!("0.17.0")
    assert result.ok, result.message
    assert_equal ["tar", RbConfig.ruby, RbConfig.ruby], ran.map { |argv, _| argv.first }
    assert_equal %w[-S gem build soft_foundry.gemspec], ran[1][0][1..]
    assert_match(%r{/soft_foundry-0\.17\.0\.gem\z}, ran[2][0].last)
  end

  def test_refuses_a_gem_whose_name_is_not_the_release
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: "https://example.test/other.gem", tarball_url: nil)
    u, ran = updater(release, downloads: { release.gem_url => { name: "evil-9.9.9.gem" } })
    result = u.install!("0.17.0")
    refute result.ok
    assert_includes result.message, "evil-9.9.9.gem"
    assert_empty ran, "nothing is installed"
  end

  def test_refuses_to_install_a_version_other_than_the_release_found
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: "https://example.test/soft_foundry-0.17.0.gem", tarball_url: nil)
    u, ran = updater(release)
    result = u.install!("0.18.0")
    refute result.ok
    assert_includes result.message, "0.18.0"
    assert_empty ran
  end

  def test_a_release_with_neither_gem_nor_source_cannot_be_installed
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: nil, tarball_url: nil)
    u, ran = updater(release)
    refute u.install!("0.17.0").ok
    assert_empty ran
  end

  def test_a_failed_download_is_reported_not_raised
    release = SoftFoundry::Updater::Release.new(version: "0.17.0", gem_url: "https://example.test/soft_foundry-0.17.0.gem", tarball_url: nil)
    u, = updater(release, downloads: {})
    result = u.install!("0.17.0")
    refute result.ok
    assert_includes result.message, "example.test"
  end
end

class UpdaterGithubFetchTest < Minitest::Test
  # The HTTP layer, with the client replaced.
  def fetch_with(code, body)
    response = Struct.new(:code, :body).new(code, body)
    def response.is_a?(klass) = klass == Net::HTTPSuccess ? code == "200" : super
    SoftFoundry::Updater.new(current: "0.16.0", http: ->(_uri, _headers) { response }).check
  end

  def test_a_published_release_is_found
    result = fetch_with("200", JSON.generate(UpdaterGithubTest::RELEASE))
    assert result.update_available
    assert_equal "0.17.0", result.latest
  end

  def test_no_release_yet_is_said_plainly
    result = fetch_with("404", "{}")
    refute result.update_available
    assert_includes result.error, "no release has been published"
    assert_includes result.error, "github.com/jmscholen/soft_foundry"
  end

  def test_rate_limit_or_other_http_errors_are_reported
    assert_includes fetch_with("403", "{}").error, "HTTP 403"
  end
end

class ReleaseWorkflowTest < Minitest::Test
  # A tag of the form v<version> builds the gem and attaches it to a GitHub
  # release, which is what `soft-foundry update` installs.
  def test_a_tag_push_publishes_the_gem_as_a_release_asset
    path = File.expand_path("../.github/workflows/release.yml", __dir__)
    assert File.file?(path), "release workflow is missing"
    workflow = YAML.safe_load_file(path)
    triggers = workflow["on"] || workflow[true] # YAML 1.1 reads a bare `on` as true
    assert_equal ["v*"], triggers.dig("push", "tags")
    assert_equal "write", workflow.dig("jobs", "release", "permissions", "contents")
    steps = workflow.dig("jobs", "release", "steps").map { |s| s["run"].to_s }.join("\n")
    assert_includes steps, "gem build soft_foundry.gemspec"
    assert_includes steps, "gh release create"
    assert_includes steps, "soft_foundry-*.gem"
    assert_match(/version\.rb|soft-foundry version/, steps, "the tag must match the version in the code")
  end

  def test_the_repository_profile_names_github_releases_not_rubygems
    profile = YAML.safe_load_file(File.expand_path("../.ai/repository.yml", __dir__))
    assert_equal ["github-releases"], profile.dig("infrastructure", "deployment_targets")
  end
end
