# frozen_string_literal: true

require_relative "test_helper"

class ManifestTest < Minitest::Test
  include FoundryFixture

  def write_manifest(dir, text)
    FileUtils.mkdir_p(File.join(dir, ".ai"))
    File.write(File.join(dir, ".ai", "manifest.yml"), text)
  end

  def test_round_trip_and_ownership
    Dir.mktmpdir do |dir|
      m = SoftFoundry::Manifest.new(soft_foundry_version: "0.2.0")
      m.add(".ai/workflow.yml", "abc")
      write_manifest(dir, m.to_yaml)
      loaded = SoftFoundry::Manifest.load(dir)
      assert loaded.owned?(".ai/workflow.yml", "abc")
      refute loaded.owned?(".ai/workflow.yml", "abd")
      assert_equal "0.2.0", loaded.soft_foundry_version
    end
  end

  def test_absent_manifest_is_empty
    Dir.mktmpdir { |dir| assert_empty SoftFoundry::Manifest.load(dir).files }
  end

  def test_schema_rejections
    Dir.mktmpdir do |dir|
      ["- list", "version: 2\nfiles: {}", "version: 1\nfiles: {'/abs': 'x'}", "version: 1\nfiles: {'.ai/../x': 'x'}",
       "version: 1\nfiles: {'lib/app.rb': 'x'}", "version: 1\nfiles: {'.ai/a': 'nothex'}"].each do |text|
        write_manifest(dir, text)
        assert_raises(SoftFoundry::TargetError, text) { SoftFoundry::Manifest.load(dir) }
      end
    end
  end

  def test_yaml_aliases_are_rejected
    Dir.mktmpdir do |dir|
      write_manifest(dir, "version: 1\nfiles: &a {}\nextra: *a\n")
      assert_raises(SoftFoundry::TargetError) { SoftFoundry::Manifest.load(dir) }
    end
  end

  def test_symlinked_manifest_is_refused
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ai"))
      File.write(File.join(dir, "outside.yml"), "version: 1\nfiles: {}\n")
      File.symlink(File.join(dir, "outside.yml"), File.join(dir, ".ai", "manifest.yml"))
      assert_raises(SoftFoundry::TargetError) { SoftFoundry::Manifest.load(dir) }
    end
  end
end
