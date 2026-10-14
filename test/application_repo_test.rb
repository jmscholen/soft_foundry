# frozen_string_literal: true

require_relative "test_helper"

# changes/factory-readiness: REQ-FR-008. The lifecycle applied to a
# Rails-shaped application repository, end to end and in process: install,
# profile, open a change, lint, guard decisions under the implementation
# skill, a passing intake gate, and the harness evals against the installed
# control plane. The fixture is file-shaped (no Rails process boots): the
# control plane decides on file presence and paths, which is what this proves.
class ApplicationRepoTest < Minitest::Test
  include FoundryFixture

  RAILS_FILES = {
    "Gemfile" => "source 'https://rubygems.org'\n\ngem 'rails', '~> 8.0'\ngem 'pg'\n\ngroup :development, :test do\n  gem 'rspec-rails'\nend\n",
    "README.md" => "# Shop\n\nA Rails application for orders and refunds.\n\n## Running\n\n```\nbin/rails server\nbundle exec rspec\n```\n\n#{'More words so the README counts as substantial. ' * 6}\n",
    "config/application.rb" => "require_relative 'boot'\nrequire 'rails/all'\n\nmodule Shop\n  class Application < Rails::Application\n    config.load_defaults 8.0\n  end\nend\n",
    "config/routes.rb" => "Rails.application.routes.draw do\n  resources :users\nend\n",
    "app/models/user.rb" => "class User < ApplicationRecord\n  validates :email, presence: true\nend\n",
    "app/controllers/users_controller.rb" => "class UsersController < ApplicationController\n  def index\n    @users = User.all\n  end\nend\n",
    "db/schema.rb" => "ActiveRecord::Schema[8.0].define(version: 1) do\n  create_table 'users' do |t|\n    t.string 'email', null: false\n  end\nend\n",
    "spec/models/user_spec.rb" => "require 'rails_helper'\n\nRSpec.describe User do\n  it 'needs an email' do\n    expect(User.new.valid?).to be(false)\n  end\nend\n",
    ".github/workflows/ci.yml" => "name: ci\non: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: bundle exec rspec\n"
  }.freeze

  def with_rails_repo
    Dir.mktmpdir("soft-foundry-rails") do |dir|
      dir = File.realpath(dir)
      RAILS_FILES.each do |rel, content|
        FileUtils.mkdir_p(File.join(dir, File.dirname(rel)))
        File.write(File.join(dir, rel), content)
      end
      sh(dir, "git", "init", "-q", "-b", "main")
      configure_git(dir)
      sh(dir, "git", "add", ".")
      sh(dir, "git", "commit", "-q", "-m", "a Rails application")
      yield dir
    end
  end

  def run_cli(dir, *args, env: {})
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil,
               "SOFT_FOUNDRY_BILLING" => nil, "SOFT_FOUNDRY_GUARD" => nil }.merge(env)) do
      code = SoftFoundry::CLI.new(args, out: out, err: err, root: dir, source: source).run
    end
    [code, out.string + err.string]
  end

  def guard_cli(dir, tool, input)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env({ "SOFT_FOUNDRY_GUARD" => nil }) do
      code = SoftFoundry::CLI.new(["guard"], out: out, err: err, input: StringIO.new(JSON.generate("tool_name" => tool, "tool_input" => input)), root: dir).run
    end
    [code, out.string + err.string]
  end

  def test_the_lifecycle_on_a_rails_shaped_repository
    with_rails_repo do |dir|
      # Install, assess, lint.
      code, out = run_cli(dir, "init", "--no-onboard")
      assert_equal 0, code, out
      assert_includes out, "check: ok"
      profile = YAML.safe_load_file(File.join(dir, ".ai/repository.yml"), permitted_classes: [Time, Date])
      assert_includes profile.dig("technology", "frameworks"), "rails"
      assert_includes profile.dig("technology", "testing"), "ruby"
      assert_equal ["block", "repository policy (.ai/policies/enforcement.yml)"], SoftFoundry::Guard.mode(dir, env: {})
      code, out = run_cli(dir, "check")
      assert_equal 0, code, out
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "install soft-foundry")

      # A change on its own branch declares the accessibility surface
      # because the profile records a user-facing framework.
      sh(dir, "git", "checkout", "-qb", "change/refund-cap")
      code, out = run_cli(dir, "change", "new", "refund-cap", "--title", "Cap refunds at the payment amount")
      assert_equal 0, code, out
      meta_path = File.join(dir, "changes/refund-cap/metadata.yml")
      meta = SoftFoundry.read_text(meta_path)
      assert_match(/^\s+accessibility: true/, meta)
      File.write(meta_path, meta.sub(/^type: TBD.*$/, "type: feature").sub(/^risk: TBD.*$/, "risk: medium")
                                .sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: implement"))
      sh(dir, "git", "add", "-A")
      sh(dir, "git", "commit", "-q", "-m", "open refund-cap")

      # Guard decisions under the implementation skill, block mode installed.
      assert_equal 0, guard_cli(dir, "Edit", { "file_path" => "app/models/user.rb" }).first
      assert_equal 0, guard_cli(dir, "Edit", { "file_path" => File.join(dir, "spec/models/user_spec.rb") }).first
      assert_equal 0, guard_cli(dir, "Write", { "file_path" => "db/migrate/20260101000000_add_refunds.rb" }).first
      assert_equal 0, guard_cli(dir, "Bash", { "command" => "bundle exec rspec spec/models" }).first
      code, out = guard_cli(dir, "Edit", { "file_path" => ".ai/rules/rails.md" })
      assert_equal 2, code
      assert_includes out, "✗ fail guard: Edit .ai/rules/rails.md is in implementation's deny_write set"
      assert_includes out, "mode: block"
      code, out = guard_cli(dir, "Edit", { "file_path" => "changes/refund-cap/06-verification/results.md" })
      assert_equal 2, code, out
      code, out = guard_cli(dir, "Read", { "file_path" => ".ai/harness-evals/README.md" })
      assert_equal 2, code
      assert_includes out, "deny_read"
      code, out = guard_cli(dir, "Bash", { "command" => "sed -i 's/block/off/' .ai/policies/enforcement.yml" })
      assert_equal 2, code
      assert_includes out, "guard's own configuration"
      code, = guard_cli(dir, "Write", { "file_path" => ".claude/settings.json" })
      assert_equal 2, code

      # A filled intake passes its gate, with the waiver rule in force.
      record = SoftFoundry::ChangeRecord.new(dir, "refund-cap", control_plane: SoftFoundry::ControlPlane.new(dir))
      complete_phase!(record, "intake", sha: head(dir))
      code, out = run_cli(dir, "gate", "intake")
      assert_equal 0, code, out
      assert_includes out, "✓ pass waivers permitted"
      assert_includes out, "✓ pass track permitted: gated"

      # The installed control plane's evals hold in this repository.
      code, out = run_cli(dir, "eval")
      assert_equal 0, code, out
      assert_includes out, "✓ pass eval control-well-formed:"
      assert_includes out, "✓ pass eval judgment-waived:"
      assert_includes out, "✓ pass eval evidence-stale-after-code-change:"
      assert_match(/✓ pass eval: \d+ passed, 0 failed, 0 errors, 1 skipped/, out)
    end
  end
end
