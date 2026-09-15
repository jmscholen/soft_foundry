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

  def test_accessibility_standard_is_a_file_fact
    with_fixture_repo do |dir|
      assert_equal "PASS", scan(dir).capabilities["accessibility.standard_in_force"].status
      File.delete(File.join(dir, ".ai/rules/accessibility.md"))
      cap = scan(dir).capabilities["accessibility.standard_in_force"]
      assert_equal "UNKNOWN", cap.status
      assert_includes cap.rationale, "accessibility.md"
    end
  end

  def test_policy_documents_are_found_where_applications_publish_them
    with_fixture_repo do |dir|
      File.write(File.join(dir, "PRIVACY.md"), "x")
      FileUtils.mkdir_p(File.join(dir, ".github")); File.write(File.join(dir, ".github/SECURITY.md"), "x")
      FileUtils.mkdir_p(File.join(dir, ".well-known")); File.write(File.join(dir, ".well-known/security.txt"), "x")
      FileUtils.mkdir_p(File.join(dir, "docs/legal")); File.write(File.join(dir, "docs/legal/Terms-of-Service.html"), "x")
      File.write(File.join(dir, "docs/legal/privacy-policy.md"), "x")
      File.write(File.join(dir, "docs/legal/security-review-notes.md"), "not a policy")
      policies = scan(dir).policies
      assert_equal({ "status" => "PASS", "evidence" => ["PRIVACY.md", "docs/legal/privacy-policy.md"] }, policies["privacy"])
      assert_equal [".github/SECURITY.md", ".well-known/security.txt"], policies["security"]["evidence"]
      assert_equal ["docs/legal/Terms-of-Service.html"], policies["terms"]["evidence"]
    end
  end

  def test_absent_policy_documents_are_unknown_not_missing
    with_fixture_repo do |dir|
      policies = scan(dir).policies
      %w[privacy security terms].each do |name|
        assert_equal "UNKNOWN", policies[name]["status"], name
        assert_includes policies[name]["rationale"], "discovery must record"
      end
    end
  end

  def test_policy_conformance_standard_is_a_file_fact
    with_fixture_repo do |dir|
      assert_equal "PASS", scan(dir).capabilities["policy_conformance.standard_in_force"].status
      File.delete(File.join(dir, ".ai/rules/policy-conformance.md"))
      cap = scan(dir).capabilities["policy_conformance.standard_in_force"]
      assert_equal "UNKNOWN", cap.status
      assert_includes cap.rationale, "policy-conformance.md"
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
      assert_equal "UNKNOWN", data.dig("policies", "privacy", "status"), "the scan records what it could not find as UNKNOWN"
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
