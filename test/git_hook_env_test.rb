# frozen_string_literal: true

require_relative "lifecycle_fixture"

# Git calls made by the tool, including the harness evals' scratch
# repositories, ignore the variables git exports to a hook. Found when the
# first `phase seal` ran `ci` from the pre-commit hook: GIT_INDEX_FILE named
# the committing repository's temporary index, and the scratch `add -A`
# wrote the planted records into it, so the seal's commit failed with an
# invalid object.
class GitHookEnvTest < Minitest::Test
  include LifecycleFixture

  def test_git_ignores_an_inherited_index_file
    with_fixture_repo do |dir|
      Dir.mktmpdir do |tmp|
        bogus = File.join(tmp, "someone-elses-index")
        with_env("GIT_INDEX_FILE" => bogus, "GIT_DIR" => File.join(tmp, "nowhere")) do
          files = SoftFoundry::Git.new(dir).tracked_files
          assert_includes files, "lib/app.rb", "the repository's own index is read, not the inherited one"
          refute File.exist?(bogus)
        end
      end
    end
  end

  def test_harness_eval_scratch_repositories_never_touch_an_inherited_index
    with_fixture_repo do |dir|
      Dir.mktmpdir do |tmp|
        committing_index = File.join(tmp, "index.lock")
        with_env("GIT_INDEX_FILE" => committing_index) do
          results = SoftFoundry::HarnessEval::Runner.new(dir).run(live: false)
          refute_empty results
          assert results.all? { |r| %w[pass skip].include?(r.outcome) }, results.map { |r| "#{r.id}: #{r.outcome} #{r.detail}" }.join("\n")
          refute File.exist?(committing_index), "a scratch repository wrote into the inherited index"
        end
      end
      assert_empty sh(dir, "git", "ls-files", "--", "changes").lines.grep(/changes\/eval-/), "no planted record reached this repository's index"
    end
  end

  def test_a_seal_inside_a_hook_that_runs_ci_commits_cleanly
    with_lifecycle_record(complete: [], current_phase: "intake", status: "intake") do |dir, record|
      hook = File.join(dir, ".git", "hooks", "pre-commit")
      exe = File.join(FoundryFixture::REPO_ROOT, "exe", "soft-foundry")
      File.write(hook, "#!/bin/sh\nexec ruby -I#{File.join(FoundryFixture::REPO_ROOT, 'lib')} #{exe} ci\n")
      File.chmod(0o755, hook)
      complete_phase!(record, "intake", sha: head(dir))
      code, out, err = run_cli(dir, "phase", "seal", "intake")
      assert_equal 0, code, out + err
      assert_equal "Record c1 intake", sh(dir, "git", "log", "--format=%s", "-n", "1").strip
      assert_empty sh(dir, "git", "ls-files", "--", "changes").lines.grep(/changes\/eval-/)
    end
  end
end
