# frozen_string_literal: true

require "json"
require "time"
require "yaml"
require_relative "safe_write"

module SoftFoundry
  # Deterministic maturity assessment: detects technology, testing, and
  # infrastructure from file presence alone, and scores only the maturity
  # capabilities that file presence can honestly answer (roughly levels 1-2).
  # Everything a scan cannot determine is left UNKNOWN, never guessed - per
  # .ai/maturity.yml's own assessment_rules. Levels 3 and above require proof
  # that changes actually went through the lifecycle (specs, verification,
  # attack, judgment), which a fresh scan of an unstarted repository cannot
  # manufacture.
  class MaturityScan
    Finding = Data.define(:status, :evidence, :rationale)

    LANGUAGES = {
      "ruby" => ["Gemfile", "*.gemspec", "Rakefile"],
      "javascript" => ["package.json"],
      "typescript" => ["tsconfig.json"],
      "python" => ["requirements.txt", "pyproject.toml", "setup.py", "Pipfile"],
      "go" => ["go.mod"],
      "rust" => ["Cargo.toml"],
      "java" => ["pom.xml", "build.gradle", "build.gradle.kts"],
      "php" => ["composer.json"],
      "elixir" => ["mix.exs"],
      "csharp" => ["*.csproj", "*.sln"]
    }.freeze

    IAC = {
      "terraform_or_opentofu" => ["*.tf"],
      "pulumi" => ["Pulumi.yaml", "Pulumi.yml"],
      "cloudformation_or_cdk" => ["cdk.json"],
      "serverless" => ["serverless.yml", "serverless.yaml"],
      "kubernetes" => ["k8s/**/*.yaml", "k8s/**/*.yml", "kubernetes/**/*.yaml"],
      "docker" => ["Dockerfile", "docker-compose.yml", "docker-compose.yaml"]
    }.freeze

    TESTING = {
      "ruby" => ["spec/**/*_spec.rb", "test/**/*_test.rb"],
      "javascript_or_typescript" => ["**/*.test.js", "**/*.spec.js", "**/*.test.ts", "__tests__/**/*"],
      "python" => ["tests/**/*.py", "test_*.py", "pytest.ini"]
    }.freeze

    attr_reader :root, :plane

    def initialize(root, control_plane:)
      @root = File.expand_path(root)
      @plane = control_plane
    end

    def technology
      {
        "languages" => LANGUAGES.filter_map { |name, globs| name if any_match?(globs) }.sort,
        "frameworks" => detected_frameworks,
        "databases" => [],
        "testing" => TESTING.filter_map { |name, globs| name if any_match?(globs) }.sort
      }
    end

    def infrastructure
      detected = IAC.filter_map { |name, globs| name if any_match?(globs) }.sort
      {
        "detected" => detected,
        "iac" => { "tools" => detected.select { |d| %w[terraform_or_opentofu pulumi cloudformation_or_cdk serverless].include?(d) } },
        "deployment_targets" => []
      }
    end

    def capabilities
      tech = technology
      infra = infrastructure
      {
        "repository.git_detected" => file_finding(".git", status: File.directory?(File.join(root, ".git")) ? "PASS" : "UNKNOWN"),
        "repository.agent_bootstrap" => file_finding("AGENTS.md"),
        "repository.execution_path_known" => execution_path_finding,
        "architecture.documented_or_discoverable" => readme_or_docs_finding,
        "coding_standards.defined" => file_finding(".ai/rules", label: ".ai/rules (installed by Soft Foundry)"),
        "technology.languages_detected" => tech["languages"].empty? ? unknown("no recognized language manifest found") : detected(tech["languages"].map { |l| "detected: #{l}" }),
        "technology.frameworks_detected" => framework_finding(tech),
        "infrastructure.detected_or_not_applicable" => infra["detected"].empty? ? not_applicable("no IaC, container, or deployment manifest found") : detected(infra["detected"]),
        "testing.strategy_detected" => tech["testing"].empty? ? unknown("no recognized test directory or framework found") : detected(tech["testing"])
      }
    end

    # Writes .ai/repository.yml. Returns the computed maturity summary.
    def run!(now: Time.now)
      commit = capture("git", "rev-parse", "HEAD").strip
      commit = nil if commit.empty?
      data = {
        "version" => 1,
        "repository" => { "assessed" => true, "assessed_at" => now.utc.iso8601, "commit_sha" => commit, "assessed_by" => "soft-foundry (maturity scan)" },
        "technology" => technology,
        "infrastructure" => infrastructure,
        "capabilities" => capabilities.transform_values { |f| { "status" => f.status, "evidence" => f.evidence, "rationale" => f.rationale }.compact },
        "maturity" => nil
      }
      maturity = plane.score_maturity(data["capabilities"])
      data["maturity"] = maturity
      SafeWrite.write(File.join(root, "repository.yml".then { |f| ".ai/#{f}" }), YAML.dump(data))
      maturity
    end

    private

    def detected_frameworks
      found = []
      found << "rails" if file?("config/application.rb") || content_includes?("Gemfile", "rails")
      found << "sinatra" if content_includes?("Gemfile", "sinatra")
      pkg = package_json
      if pkg
        deps = Hash(pkg["dependencies"]).merge(Hash(pkg["devDependencies"]))
        %w[express next react vue @angular/core].each { |name| found << name.sub("@angular/core", "angular") if deps.key?(name) }
      end
      found << "django" if content_includes?("requirements.txt", "django") || content_includes?("pyproject.toml", "django")
      found << "flask" if content_includes?("requirements.txt", "flask")
      found << "fastapi" if content_includes?("requirements.txt", "fastapi")
      found.uniq.sort
    end

    def framework_finding(tech)
      frameworks = tech["frameworks"]
      return detected(frameworks.map { |f| "detected: #{f}" }) unless frameworks.empty?
      return not_applicable("bin/lib/exe layout with a gemspec suggests a library, not an application") if gem_library_shape?
      unknown("no recognized application framework found; may be a library, script collection, or an unrecognized framework")
    end

    def gem_library_shape?
      any_match?(["*.gemspec"]) && file?("lib") && file?("exe") || file?("bin")
    end

    def execution_path_finding
      signals = []
      signals << "README.md" if file?("README.md")
      signals << "Rakefile" if file?("Rakefile")
      signals << "Makefile" if file?("Makefile")
      signals << "package.json scripts" if package_json&.key?("scripts")
      signals << "CI workflow" if file?(".github/workflows")
      return detected(signals) if signals.size >= 2
      unknown("fewer than two independent signals of a known run/build path (README, Rakefile/Makefile, package.json scripts, CI workflow)")
    end

    def readme_or_docs_finding
      return detected(["README.md"]) if file?("README.md") && File.size(File.join(root, "README.md")) > 200
      return detected(["docs/"]) if file?("docs")
      unknown("no substantial README.md or docs/ directory found")
    end

    def file_finding(rel, status: nil, label: nil)
      present = file?(rel)
      Finding.new(status: status || (present ? "PASS" : "UNKNOWN"), evidence: present ? [label || rel] : [], rationale: present ? nil : "#{rel} not found")
    end

    def detected(evidence) = Finding.new(status: "PASS", evidence: Array(evidence), rationale: nil)
    def unknown(rationale) = Finding.new(status: "UNKNOWN", evidence: [], rationale: rationale)
    def not_applicable(rationale) = Finding.new(status: "NOT_APPLICABLE", evidence: [], rationale: rationale)

    def file?(rel) = File.exist?(File.join(root, rel))

    def any_match?(globs)
      globs.any? { |g| !Dir.glob(g, File::FNM_DOTMATCH, base: root).reject { |p| p.start_with?(".") && p != g }.empty? || file?(g) }
    end

    def content_includes?(rel, needle)
      path = File.join(root, rel)
      File.file?(path) && File.read(path).include?(needle)
    rescue StandardError
      false
    end

    def package_json
      path = File.join(root, "package.json")
      return nil unless File.file?(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError, StandardError
      nil
    end

    def capture(*cmd)
      require "open3"
      out, _err, status = Open3.capture3(*cmd, chdir: root)
      status.success? ? out : ""
    rescue Errno::ENOENT
      ""
    end
  end
end
