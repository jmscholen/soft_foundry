# frozen_string_literal: true

require_relative "test_helper"

class MaturityScanTest < Minitest::Test
  include FoundryFixture

  def scan(dir) = SoftFoundry::MaturityScan.new(dir, control_plane: SoftFoundry::ControlPlane.new(dir))

  def test_detects_ruby_rails_and_tests
    with_fixture_repo do |dir|
      File.write(File.join(dir, "Gemfile"), "gem 'rails'\ngem 'rspec'\n")
      FileUtils.mkdir_p(File.join(dir, "spec")); File.write(File.join(dir, "spec/foo_spec.rb"), "x")
      tech = scan(dir).technology
      assert_includes tech["languages"], "ruby"
      assert_includes tech["frameworks"], "rails"
      assert_includes tech["testing"], "ruby"
    end
  end

  def test_detects_node_react_and_iac
    with_fixture_repo do |dir|
      File.write(File.join(dir, "package.json"), '{"dependencies": {"react": "18.0.0"}, "scripts": {"test": "jest"}}')
      File.write(File.join(dir, "main.tf"), "resource \"x\" \"y\" {}")
      tech = scan(dir).technology
      infra = scan(dir).infrastructure
      assert_includes tech["languages"], "javascript"
      assert_includes tech["frameworks"], "react"
      assert_includes infra["detected"], "terraform_or_opentofu"
      assert_includes infra["iac"]["tools"], "terraform_or_opentofu"
    end
  end

  def test_gem_library_shape_is_not_applicable_for_frameworks
    with_fixture_repo do |dir|
      File.write(File.join(dir, "x.gemspec"), "x")
      FileUtils.mkdir_p(File.join(dir, "lib")); FileUtils.mkdir_p(File.join(dir, "exe"))
      cap = scan(dir).capabilities["technology.frameworks_detected"]
      assert_equal "NOT_APPLICABLE", cap.status
    end
  end

  def test_unrecognized_shape_is_unknown_not_missing
    with_fixture_repo do |dir|
      cap = scan(dir).capabilities["technology.frameworks_detected"]
      assert_equal "UNKNOWN", cap.status
      infra_cap = scan(dir).capabilities["infrastructure.detected_or_not_applicable"]
      assert_equal "NOT_APPLICABLE", infra_cap.status
    end
  end

  def test_execution_path_needs_at_least_two_signals
    with_fixture_repo do |dir|
      File.write(File.join(dir, "README.md"), "x" * 300)
      assert_equal "UNKNOWN", scan(dir).capabilities["repository.execution_path_known"].status
      File.write(File.join(dir, "Rakefile"), "task :x")
      assert_equal "PASS", scan(dir).capabilities["repository.execution_path_known"].status
    end
  end

  def test_run_writes_repository_yml_with_computed_maturity
    with_fixture_repo do |dir|
      File.write(File.join(dir, "AGENTS.md"), "x"); File.write(File.join(dir, "README.md"), "x" * 300)
      File.write(File.join(dir, "Rakefile"), "task :x")
      result = scan(dir).run!
      assert result["current_level"] >= 1
      data = YAML.safe_load_file(File.join(dir, ".ai/repository.yml"))
      assert data.dig("repository", "assessed")
      assert data["repository"]["commit_sha"]
      assert_equal result, data["maturity"]
    end
  end

  def test_run_refuses_a_symlinked_repository_yml
    with_fixture_repo do |dir|
      Dir.mktmpdir do |outside|
        victim = File.join(outside, "v"); File.write(victim, "mine")
        FileUtils.rm_f(File.join(dir, ".ai/repository.yml"))
        File.symlink(victim, File.join(dir, ".ai/repository.yml"))
        assert_raises(SoftFoundry::TargetError) { scan(dir).run! }
        assert_equal "mine", File.read(victim)
      end
    end
  end
end
