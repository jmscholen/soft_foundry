# frozen_string_literal: true

require_relative "test_helper"

# Scoped verification: a record may declare the paths it owns, a repository
# may declare a shared core and its access-control paths, and commit-bound
# evidence goes stale for the paths that matter to it rather than for any
# code change. See changes/scoped-verification/.
class ScopedVerificationTest < Minitest::Test
  include FoundryFixture

  CHECK = "evidence current"
  FULL_SUITE = "full-suite run recorded (record check, not a test result)"
  SIZE = "check size matches diff"

  # --- fixtures --------------------------------------------------------

  def with_repo(shared_core: nil, access_control: nil)
    with_fixture_repo do |dir|
      %w[a b base other auth].each do |d|
        FileUtils.mkdir_p(File.join(dir, "lib", d))
        File.write(File.join(dir, "lib", d, "f.rb"), "puts '#{d}'\n")
      end
      profile = File.join(dir, ".ai", "repository.yml")
      text = File.read(profile)
      text += "\n" unless text.end_with?("\n")
      text += "shared_core:\n#{Array(shared_core).map { |g| "  - #{g}\n" }.join}" if shared_core
      text += "access_control:\n#{Array(access_control).map { |g| "  - #{g}\n" }.join}" if access_control
      File.write(profile, text)
      commit_all(dir, "fixture code")
      yield dir
    end
  end

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def git(dir) = SoftFoundry::Git.new(dir)
  def gate(record, dir, git: git(dir)) = SoftFoundry::Gate.new(record, git: git)

  def edit_metadata(dir, slug)
    path = File.join(dir, "changes", slug, "metadata.yml")
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date])
    yield data
    File.write(path, YAML.dump(data))
  end

  # A record on main with phases up to `through` complete at one commit.
  def make_record(dir, slug, scope: nil, status: nil, through: 7, evidence: nil)
    cli(dir, "change", "new", slug)
    edit_metadata(dir, slug) do |m|
      m["scope"] = scope unless scope.nil?
      m["status"] = status if status
    end
    record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane(dir))
    commit_all(dir, "record #{slug}")
    sha = evidence || head(dir)
    plane(dir).phases.take(through).each { |p| complete_phase!(record, p.id, sha: sha) }
    commit_all(dir, "#{slug} phases complete") if through.positive?
    record
  end

  def touch(dir, rel, body = "puts #{rand(1_000_000)}\n")
    path = File.join(dir, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, body)
  end

  def commit_code(dir, rel) = (touch(dir, rel); commit_all(dir, "change #{rel}"))

  def check(gate, name, phase: "verify") = gate.evaluate(phase).checks.find { |c| c.name == name }
  def current(gate) = check(gate, CHECK)

  def write_tests_yml(record, data)
    File.write(File.join(record.dir, "06-verification", "tests.yml"), YAML.dump(data))
  end

  def tree(dir, sha = "HEAD") = sh(dir, "git", "rev-parse", "#{sha}^{tree}").strip

  class CountingGit < SoftFoundry::Git
    attr_reader :calls

    def run(*args)
      (@calls ||= []) << args
      super
    end
  end

  class FailingGit < SoftFoundry::Git
    def diff_paths(*) = raise(SoftFoundry::GitError, "git diff failed: simulated")
  end

  # --- git wrapper -------------------------------------------------------

  def test_diff_paths_fails_closed_on_an_unknown_commit
    with_repo do |dir|
      assert_raises(SoftFoundry::GitError) { git(dir).diff_paths("0" * 40) }
    end
  end

  def test_diff_paths_lists_committed_and_uncommitted_paths
    with_repo do |dir|
      base = head(dir)
      commit_code(dir, "lib/a/new.rb")
      touch(dir, "lib/b/dirty.rb")
      assert_equal %w[lib/a/new.rb lib/b/dirty.rb], git(dir).diff_paths(base)
      assert_equal %w[lib/a/new.rb], git(dir).diff_paths(base, head(dir))
    end
  end

  def test_tree_of_returns_the_tree_and_refuses_anything_that_is_not_a_sha
    with_repo do |dir|
      assert_equal tree(dir), git(dir).tree_of(head(dir))
      assert_raises(SoftFoundry::GitError) { git(dir).tree_of("--output=/tmp/x") }
      assert_raises(SoftFoundry::GitError) { git(dir).tree_of("f" * 40) }
    end
  end

  def test_code_dirty_paths_counts_modified_untracked_and_ignored_directories
    with_repo do |dir|
      assert_empty git(dir).code_dirty_paths(%w[lib/**])
      touch(dir, "lib/a/f.rb", "changed\n")
      assert_equal %w[lib/a/f.rb], git(dir).code_dirty_paths(%w[lib/**])
      sh(dir, "git", "checkout", "--", "lib/a/f.rb")
      File.write(File.join(dir, ".gitignore"), "lib/cache/\n")
      commit_all(dir, "ignore cache")
      touch(dir, "lib/cache/blob.rb")
      assert_equal %w[lib/cache/], git(dir).code_dirty_paths(%w[lib/**])
      assert_empty git(dir).code_dirty_paths(%w[app/**])
    end
  end

  # --- declarations ------------------------------------------------------

  def problems(list, kind: :scope, tracked: %w[lib/a/f.rb lib/base/f.rb], code: %w[lib/**])
    SoftFoundry::Declarations.problems(list, tracked_files: tracked, code_globs: code, kind: kind)
  end

  def test_a_well_formed_declaration_has_no_problems
    assert_empty problems(%w[lib/a/**])
    assert_empty problems(%w[lib/base/**], kind: :shared_core)
  end

  def test_malformed_globs_are_refused_with_the_glob_named
    ["", "/etc/**", "lib/../x/**", "-rf", "lib/a\nb", "lib/a\0b", "lib/nothing/**", "x" * 300].each do |glob|
      found = problems([glob])
      refute_empty found, glob.inspect
    end
    assert_includes problems(["/etc/**"]).join, "/etc/**"
    assert_includes problems(["lib/nothing/**"]).join, "matches no tracked file"
  end

  def test_brace_blowup_is_refused
    refute_empty problems(["lib/{a,b}/{a,b}/{a,b}/{a,b}/{a,b}/{a,b}/**"])
  end

  def test_a_scope_must_be_a_list
    refute_empty SoftFoundry::Declarations.problems("lib/**", tracked_files: [], code_globs: %w[lib/**], kind: :scope)
  end

  def test_a_shared_core_outside_the_code_groups_is_refused
    found = problems(%w[docs/**], kind: :shared_core, tracked: %w[docs/a.md])
    assert_includes found.join, "code path groups"
  end

  def test_the_matcher_is_fast_on_hostile_input
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    SoftFoundry::ControlPlane.match?("a/" * 500 + "x", "**/**/**/*a*a*a*a*b")
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1.0
  end

  # --- staleness: the default is unchanged (AC-001) ----------------------

  def test_unscoped_and_empty_scope_records_are_stale_identically
    with_repo do |dir|
      none = make_record(dir, "none")
      empty = make_record(dir, "empty", scope: [])
      commit_code(dir, "lib/a/f.rb")
      [none, empty].each do |record|
        c = current(gate(record, dir))
        assert_equal :fail, c.outcome
        assert_includes c.detail, "STALE: code changed since"
        assert_includes c.detail, "lib/a/f.rb"
      end
      detail = ->(record) { current(gate(record, dir)).detail.gsub(/\b[0-9a-f]{12}\b/, "SHA") }
      assert_equal detail.call(none), detail.call(empty)
    end
  end

  # --- staleness: scoped (AC-002..AC-005) --------------------------------

  def test_a_change_in_scope_stales_only_its_record
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/a/f.rb")
      ca = current(gate(a, dir))
      assert_equal :fail, ca.outcome
      assert_includes ca.detail, "scope: lib/a/**"
      assert_includes ca.detail, "reason: lib/a/f.rb: in scope"
      cb = current(gate(b, dir))
      assert_equal :pass, cb.outcome, cb.detail
    end
  end

  def test_a_shared_core_change_stales_every_record
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/base/f.rb")
      [a, b].each do |record|
        c = current(gate(record, dir))
        assert_equal :fail, c.outcome
        assert_includes c.detail, "reason: lib/base/f.rb: shared core"
      end
    end
  end

  def test_an_unclaimed_path_stales_a_scoped_record
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/other/f.rb")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "reason: lib/other/f.rb: unclaimed"
    end
  end

  def test_a_path_claimed_only_by_a_closed_or_malformed_record_is_unclaimed
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "old", scope: %w[**], status: "closed")
      make_record(dir, "bad", scope: "lib/other/**")
      commit_code(dir, "lib/other/f.rb")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "lib/other/f.rb: unclaimed"
    end
  end

  def test_a_path_claimed_by_another_active_record_does_not_stale_this_one
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/b/f.rb")
      c = current(gate(a, dir))
      assert_equal :pass, c.outcome, c.detail
      assert_includes c.detail, "scope: lib/a/**"
    end
  end

  def test_non_code_changes_never_stale_a_scoped_record
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "notes/readme.md")
      assert_equal :pass, current(gate(a, dir)).outcome
    end
  end

  # --- staleness: other causes unchanged (AC-006) ------------------------

  def test_a_re_recorded_specification_still_stales_a_scoped_record
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      assert_equal :pass, current(gate(a, dir)).outcome
      spec = plane(dir).phase("specify")
      path = a.handoff_path(spec)
      File.write(path, File.read(path) + "\n# re-recorded\n")
      commit_all(dir, "re-record specification")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "the specification was re-recorded"
    end
  end

  # --- staleness: declarations are evidence too (AC-007) -----------------

  def test_narrowing_the_scope_after_the_evidence_stales_it
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/** lib/b/**])
      assert_equal :pass, current(gate(a, dir)).outcome
      edit_metadata(dir, "a") { |m| m["scope"] = %w[lib/a/**] }
      commit_all(dir, "narrow scope")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "declaration changed"
      assert_includes c.detail, "scope"
    end
  end

  def test_changing_shared_core_or_access_control_after_the_evidence_stales_it
    with_repo(shared_core: %w[lib/base/**], access_control: %w[lib/auth/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      assert_equal :pass, current(gate(a, dir)).outcome
      profile = File.join(dir, ".ai", "repository.yml")
      File.write(profile, File.read(profile).sub("lib/base/**", "lib/other/**"))
      commit_all(dir, "move core")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "declaration changed: shared_core"
    end
    with_repo(shared_core: %w[lib/base/**], access_control: %w[lib/auth/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      profile = File.join(dir, ".ai", "repository.yml")
      File.write(profile, File.read(profile).sub("lib/auth/**", "lib/other/**"))
      commit_all(dir, "move access control")
      assert_includes current(gate(a, dir)).detail, "declaration changed: access_control"
    end
  end

  def test_editing_the_sizing_policy_after_the_evidence_stales_it
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      FileUtils.mkdir_p(File.join(dir, ".ai", "policies"))
      File.write(File.join(dir, ".ai", "policies", "check-sizing.yml"), "sizes: {}\n")
      commit_all(dir, "add sizing policy")
      assert_includes current(gate(a, dir)).detail, "declaration changed: check-sizing policy"
    end
  end

  # --- git failure fails closed (AC-016) ---------------------------------

  def test_a_git_failure_reads_as_stale_with_the_cause_named
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      c = current(gate(a, dir, git: FailingGit.new(dir)))
      assert_equal :fail, c.outcome
      assert_includes c.detail, "STALE"
      assert_includes c.detail, "simulated"
    end
  end

  # --- one decision (AC-018) --------------------------------------------

  def test_status_snapshot_and_phase_run_agree_on_a_record_current_for_its_scope
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/b/f.rb")
      # b's commit lies on this branch too, so a's diff is not wholly in scope: the full suite is owed
      run = { "tree" => evidence_tree(a, dir), "command" => "bin/rails test", "outcome" => "passed" }
      write_tests_yml(a, "commit_sha" => head(dir), "size" => "full_at_verify", "full_suite" => run)
      code, out = cli(dir, "change", "status", "a")
      assert_equal 0, code, out
      assert_includes out, "scope: lib/a/**"
      refute_includes out, "STALE"
      snap = SoftFoundry::Snapshot.new(dir, plane: plane(dir), git: git(dir), index: SoftFoundry::ChangeIndex.new(dir, plane: plane(dir), git: git(dir)))
      refute snap.change("a")["stale"]
      assert_equal %w[lib/a/**], snap.change("a")["scope"]
      runner = SoftFoundry::PhaseRunner.new(dir, plane: plane(dir), git: git(dir), record: a)
      assert_includes runner.refusal(plane(dir).phase("verify")), "already complete"
    end
  end

  def test_consumers_hold_no_staleness_logic_of_their_own
    %w[phase_runner.rb snapshot.rb cli.rb advisory.rb].each do |file|
      source = File.read(File.join(REPO_ROOT, "lib", "soft_foundry", file))
      refute_includes source, "code changed since", "#{file} must read the gate's result, not decide staleness"
    end
  end

  # --- sizing (AC-011, AC-013, AC-014, AC-019) ---------------------------

  def size(dir, slug, *args) = cli(dir, "change", "size", slug, *args)

  def sized_record(dir, slug, scope:)
    make_record(dir, slug, scope: scope, through: 5)
  end

  def test_a_diff_inside_the_scope_is_targeted_plus_one_full_run
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      code, out = size(dir, "a", "--phase", "verify")
      assert_equal 0, code, out
      assert_includes out, "size: targeted_plus_full_before_merge"
      assert_includes out, "scope: lib/a/**"
      assert_includes out, "reason: lib/a/f.rb: in scope"
    end
  end

  def test_a_shared_core_or_outside_diff_is_the_full_suite_at_verify
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      commit_code(dir, "lib/base/f.rb")
      _, out = size(dir, "a", "--phase", "verify")
      assert_includes out, "size: full_at_verify"
      assert_includes out, "reason: lib/base/f.rb: shared core"
    end
    with_repo do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/other/f.rb")
      _, out = size(dir, "a", "--phase", "verify")
      assert_includes out, "size: full_at_verify"
      assert_includes out, "reason: lib/other/f.rb: unclaimed"
    end
  end

  def test_evaluate_and_attack_sweep_fully_only_when_access_control_is_touched
    with_repo(access_control: %w[lib/auth/**]) do |dir|
      sized_record(dir, "a", scope: %w[lib/a/** lib/auth/**])
      commit_code(dir, "lib/a/f.rb")
      %w[evaluate attack].each do |phase|
        _, out = size(dir, "a", "--phase", phase)
        assert_includes out, "size: touched_doors_plus_smoke", out
      end
      commit_code(dir, "lib/auth/f.rb")
      %w[evaluate attack].each do |phase|
        _, out = size(dir, "a", "--phase", phase)
        assert_includes out, "size: full_route_sweep"
        assert_includes out, "reason: lib/auth/f.rb: access control"
      end
    end
  end

  def test_no_access_control_declaration_or_no_scope_means_the_full_sweep
    with_repo do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      _, out = size(dir, "a", "--phase", "evaluate")
      assert_includes out, "size: full_route_sweep"
    end
    with_repo(access_control: %w[lib/auth/**]) do |dir|
      sized_record(dir, "a", scope: nil)
      commit_code(dir, "lib/a/f.rb")
      _, out = size(dir, "a", "--phase", "evaluate")
      assert_includes out, "size: full_route_sweep"
      assert_includes out, "scope: whole repository"
    end
  end

  def test_the_diff_base_is_the_record_branch_tip_when_it_is_not_checked_out
    with_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/a")
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      sh(dir, "git", "checkout", "-qb", "change/b")
      commit_code(dir, "lib/other/f.rb")
      _, out = size(dir, "a", "--phase", "verify")
      assert_includes out, "size: targeted_plus_full_before_merge", out
      refute_includes out, "lib/other/f.rb"
    end
  end

  def test_sizing_without_a_plan_commit_says_what_to_do
    with_repo do |dir|
      make_record(dir, "a", scope: %w[lib/a/**], through: 0)
      code, out = size(dir, "a", "--phase", "verify")
      refute_equal 0, code
      assert_includes out, "--since"
    end
  end

  def test_since_names_the_diff_base
    with_repo do |dir|
      make_record(dir, "a", scope: %w[lib/a/**], through: 0)
      base = head(dir)
      commit_code(dir, "lib/a/f.rb")
      code, out = size(dir, "a", "--phase", "verify", "--since", base)
      assert_equal 0, code, out
      assert_includes out, "base: #{base}"
    end
  end

  def test_size_output_is_words_prefixed_lines_with_no_prompt_and_plain_ascii
    with_repo do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      code, out = with_env("NO_COLOR" => "1") { size(dir, "a", "--phase", "verify") }
      assert_equal 0, code
      assert out.ascii_only?, out
      out.lines.each { |l| assert_match(/\A(size|scope|reason|base|phase): /, l) }
    end
  end

  def test_the_size_command_refuses_an_unknown_phase_and_says_the_fix
    with_repo do |dir|
      sized_record(dir, "a", scope: %w[lib/a/**])
      code, out = size(dir, "a", "--phase", "deploy")
      refute_equal 0, code
      assert_includes out, "verify, evaluate, attack"
    end
  end

  # --- the recorded size is checked (AC-012) -----------------------------

  def test_a_recorded_size_smaller_than_the_computed_one_fails_naming_both
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**], through: 7)
      commit_code(dir, "lib/base/f.rb")
      write_tests_yml(a, "commit_sha" => head(dir), "size" => "targeted_plus_full_before_merge")
      c = check(gate(a, dir), SIZE)
      assert_equal :fail, c.outcome
      assert_includes c.detail, "targeted_plus_full_before_merge"
      assert_includes c.detail, "full_at_verify"
      write_tests_yml(a, "commit_sha" => head(dir), "size" => "full_at_verify")
      assert_equal :pass, check(gate(a, dir), SIZE).outcome
    end
  end

  def test_a_scoped_record_with_no_recorded_size_fails_with_the_fix_named
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      write_tests_yml(a, "commit_sha" => head(dir))
      c = check(gate(a, dir), SIZE)
      assert_equal :fail, c.outcome
      assert_includes c.detail, "size:"
    end
  end

  def test_an_unscoped_record_is_not_asked_for_a_size
    with_repo do |dir|
      a = make_record(dir, "a")
      write_tests_yml(a, "commit_sha" => head(dir))
      assert_equal :skip, check(gate(a, dir), SIZE).outcome
      assert_equal :skip, check(gate(a, dir), FULL_SUITE).outcome
    end
  end

  # --- full-suite record and citation (AC-008, AC-009, AC-010) ----------

  def full_suite(record, dir, block, size: "targeted_plus_full_before_merge")
    write_tests_yml(record, "commit_sha" => head(dir), "size" => size, "full_suite" => block)
    check(gate(record, dir), FULL_SUITE)
  end

  def evidence_tree(record, dir)
    tree(dir, record.handoff(plane(dir).phase("verify"))["commit_sha"])
  end

  def test_a_recorded_full_suite_run_names_the_evidence_tree
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      ok = { "tree" => evidence_tree(a, dir), "command" => "bin/rails test", "outcome" => "passed" }
      c = full_suite(a, dir, ok)
      assert_equal :pass, c.outcome, c.detail
      assert_includes c.detail, "recorded"
      assert_equal :fail, full_suite(a, dir, ok.merge("tree" => "0" * 40)).outcome
      assert_includes full_suite(a, dir, ok.merge("tree" => "0" * 40)).detail, "run the full suite on this tree and record it in tests.yml"
      assert_equal :fail, full_suite(a, dir, ok.reject { |k, _| k == "outcome" }).outcome
      assert_equal :fail, full_suite(a, dir, ok.merge("outcome" => "failed")).outcome
      assert_equal :fail, full_suite(a, dir, ok.reject { |k, _| k == "command" }).outcome
    end
  end

  def test_a_scoped_record_with_a_computed_full_size_and_no_run_fails
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/base/f.rb")
      write_tests_yml(a, "commit_sha" => head(dir), "size" => "full_at_verify")
      assert_equal :fail, check(gate(a, dir), FULL_SUITE).outcome
    end
  end

  def test_a_scoped_targeted_record_with_no_run_skips_with_the_owed_run_named
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      write_tests_yml(a, "commit_sha" => head(dir), "size" => "targeted_plus_full_before_merge")
      c = check(gate(a, dir), FULL_SUITE)
      assert_equal :skip, c.outcome
      assert_includes c.detail, "before merge"
    end
  end

  def test_a_citation_is_accepted_only_when_the_cited_record_names_this_tree
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**], evidence: a.handoff(plane(dir).phase("verify"))["commit_sha"])
      run = { "tree" => evidence_tree(a, dir), "command" => "bin/rails test", "outcome" => "passed" }
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run)
      c = full_suite(b, dir, { "cite" => "a" })
      assert_equal :pass, c.outcome, c.detail

      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run.merge("tree" => "1" * 40))
      assert_equal :fail, full_suite(b, dir, { "cite" => "a" }).outcome
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run.merge("outcome" => "failed"))
      assert_equal :fail, full_suite(b, dir, { "cite" => "a" }).outcome
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run)
      d = full_suite(b, dir, { "cite" => "missing-record" })
      assert_equal :fail, d.outcome
      assert_includes d.detail, "run the full suite on this tree and record it in tests.yml"
    end
  end

  # --- remediation: rename, branch, claimed sizing, citation case -------

  def test_a_rename_lists_both_the_source_and_the_destination
    with_repo do |dir|
      base = head(dir)
      sh(dir, "git", "mv", "lib/auth/f.rb", "lib/a/moved.rb")
      commit_all(dir, "move")
      assert_equal %w[lib/a/moved.rb lib/auth/f.rb], git(dir).diff_paths(base, head(dir))
      assert_equal %w[lib/a/moved.rb lib/auth/f.rb], git(dir).changed_between(base, head(dir))
    end
  end

  def test_a_file_renamed_out_of_a_records_scope_stales_it
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/auth/**])
      make_record(dir, "b", scope: %w[lib/b/**])
      sh(dir, "git", "mv", "lib/auth/f.rb", "lib/b/moved.rb")
      commit_all(dir, "move")
      c = current(gate(a, dir))
      assert_equal :fail, c.outcome, c.detail
      assert_includes c.detail, "lib/auth/f.rb: in scope"
    end
  end

  def test_a_recorded_branch_that_lacks_the_evidence_commit_is_stale_not_current
    with_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "side")
      sh(dir, "git", "checkout", "-q", "-")
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b")
      commit_code(dir, "lib/a/f.rb")
      [a, b].each do |r|
        edit_metadata(dir, r.slug) { |m| m["git"] = (m["git"] || {}).merge("branch" => "side") }
        c = current(gate(SoftFoundry::ChangeRecord.new(dir, r.slug, control_plane: plane(dir)), dir))
        assert_equal :fail, c.outcome, "#{r.slug}: #{c.detail}"
        assert_includes c.detail, "does not contain the evidence commit"
      end
    end
  end

  def test_a_path_claimed_by_another_record_does_not_enlarge_the_size
    with_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/a")
      sized_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "b", scope: %w[lib/b/**])
      commit_code(dir, "lib/b/new.rb")
      _, out = size(dir, "a", "--phase", "verify")
      assert_includes out, "size: targeted_plus_full_before_merge", out
    end
  end

  def test_a_citation_slug_must_match_the_directory_name_exactly
    with_repo do |dir|
      a = make_record(dir, "alpha", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**], evidence: a.handoff(plane(dir).phase("verify"))["commit_sha"])
      run = { "tree" => evidence_tree(a, dir), "command" => "x", "outcome" => "passed" }
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run)
      assert_equal :pass, full_suite(b, dir, { "cite" => "alpha" }).outcome
      assert_equal :fail, full_suite(b, dir, { "cite" => "ALPHA" }).outcome
    end
  end

  def test_a_citation_is_refused_for_self_chains_and_hostile_names
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**], evidence: a.handoff(plane(dir).phase("verify"))["commit_sha"])
      run = { "tree" => evidence_tree(a, dir), "command" => "x", "outcome" => "passed" }
      assert_equal :fail, full_suite(a, dir, { "cite" => "a" }).outcome
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => { "cite" => "b" })
      assert_equal :fail, full_suite(b, dir, { "cite" => "a" }).outcome, "a cited run must itself hold a tree"
      ["../a", "/etc/passwd", "a/../a", "-x", "a b"].each do |slug|
        assert_equal :fail, full_suite(b, dir, { "cite" => slug }).outcome, slug
      end
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => run)
    end
  end

  def test_a_dirty_code_path_refuses_a_citation
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      b = make_record(dir, "b", scope: %w[lib/b/**], evidence: a.handoff(plane(dir).phase("verify"))["commit_sha"])
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => { "tree" => evidence_tree(a, dir), "command" => "x", "outcome" => "passed" })
      commit_all(dir, "record a's run")
      touch(dir, "lib/b/f.rb", "dirty\n")
      c = full_suite(b, dir, { "cite" => "a" })
      assert_equal :fail, c.outcome
      assert_includes c.detail, "dirty"
      assert_includes c.detail, "outside the tree hash"
    end
  end

  def test_a_failing_tree_lookup_fails_the_check_with_the_cause
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      write_tests_yml(a, "commit_sha" => head(dir), "full_suite" => { "tree" => "0" * 40, "command" => "x", "outcome" => "passed" })
      bad = Class.new(SoftFoundry::Git) { def tree_of(*) = raise(SoftFoundry::GitError, "no tree: simulated") }
      c = check(gate(a, dir, git: bad.new(dir)), FULL_SUITE)
      assert_equal :fail, c.outcome
      assert_includes c.detail, "simulated"
    end
  end

  def test_no_new_output_claims_the_suite_passed
    sources = %w[full_suite.rb scope.rb sizing.rb declarations.rb].map { |f| File.join(REPO_ROOT, "lib", "soft_foundry", f) }
    sources.select { |f| File.exist?(f) }.each do |f|
      File.read(f).scan(/"[^"\n]*"/).each do |literal|
        refute_match(/suite (has )?passed|tests? (have )?passed|proves? the suite/i, literal, "#{File.basename(f)}: #{literal}")
      end
    end
    assert_includes SoftFoundry::Gate::CHECKS.fetch(FULL_SUITE), "record"
  end

  # --- advisories (AC-017) ----------------------------------------------

  def advisories(record, dir) = SoftFoundry::Advisory.new(record, git: git(dir)).notices.select { |n| n.area == "scope" }.map(&:message)

  def test_a_diff_outside_the_declared_scope_is_advised_not_blocked
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/other/f.rb")
      assert advisories(a, dir).any? { |m| m.include?("outside the declared scope") && m.include?("lib/other/f.rb") }
      refute gate(a, dir).evaluate("verify").checks.any? { |c| c.name.include?("advis") }
    end
  end

  def test_a_shared_core_change_with_no_full_suite_run_is_advised
    with_repo(shared_core: %w[lib/base/**]) do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**], through: 5)
      commit_code(dir, "lib/base/f.rb")
      assert advisories(a, dir).any? { |m| m.include?("shared core") && m.include?("full-suite") }
    end
  end

  def test_a_scope_that_matches_no_changed_file_is_advised_once_the_work_is_done
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**], through: 6)
      assert advisories(a, dir).any? { |m| m.include?("matches no changed file") }
    end
  end

  def test_overlapping_scopes_of_active_records_are_advised
    with_repo do |dir|
      a = make_record(dir, "a", scope: %w[lib/a/**])
      make_record(dir, "twin", scope: %w[lib/a/**])
      assert advisories(a, dir).any? { |m| m.include?("overlaps") && m.include?("twin") }
    end
  end

  def test_an_unscoped_record_gets_no_scope_advisory
    with_repo do |dir|
      a = make_record(dir, "a")
      commit_code(dir, "lib/a/f.rb")
      assert_empty advisories(a, dir)
    end
  end

  # --- output contract (AC-019, AC-020) ----------------------------------

  def test_stale_output_names_scope_path_and_reason_on_their_own_lines
    with_repo do |dir|
      make_record(dir, "a", scope: %w[lib/a/**])
      commit_code(dir, "lib/a/f.rb")
      _, out = cli(dir, "gate", "verify", "--change", "a")
      assert_includes out, "STALE"
      assert_match(/^\s+scope: lib\/a\/\*\*$/, out)
      assert_match(/^\s+reason: lib\/a\/f\.rb: in scope$/, out)
    end
  end

  def test_the_snapshot_carries_scope_as_text_for_the_view
    with_repo do |dir|
      make_record(dir, "a", scope: ["lib/a/**", "<b>x</b>"])
      snap = SoftFoundry::Snapshot.new(dir, plane: plane(dir), git: git(dir), index: SoftFoundry::ChangeIndex.new(dir, plane: plane(dir), git: git(dir)))
      assert_equal ["lib/a/**", "<b>x</b>"], snap.change("a")["scope"]
      assets = Dir[File.join(REPO_ROOT, "lib", "soft_foundry", "ui", "**", "*")].select { |f| File.file?(f) }.map { |f| File.read(f) }.join
      assert_match(/scope/, assets)
      refute_match(/innerHTML\s*=[^;]*scope/, assets)
    end
  end

  # --- bounded git use (AC-022) ------------------------------------------

  def test_git_invocations_do_not_grow_with_the_number_of_changed_files
    counts = [1, 300].map do |files|
      count = nil
      with_repo do |dir|
        a = make_record(dir, "a", scope: %w[lib/a/**])
        files.times { |i| touch(dir, "lib/a/gen/f#{i}.rb") }
        commit_all(dir, "many")
        counting = CountingGit.new(dir)
        gate(a, dir, git: counting).evaluate("verify")
        count = counting.calls.size
      end
      count
    end
    assert_equal counts.first, counts.last
  end

  # --- structure check (AC-015, AC-021) ----------------------------------

  def findings(dir) = SoftFoundry::Check.new(plane(dir)).run.map(&:message)

  def test_check_refuses_a_blind_or_malformed_profile_declaration
    with_repo(shared_core: %w[docs/**]) do |dir|
      assert findings(dir).any? { |m| m.include?("shared_core") && m.include?("docs/**") }
    end
    with_repo(access_control: ["/etc/**"]) do |dir|
      assert findings(dir).any? { |m| m.include?("access_control") && m.include?("/etc/**") }
    end
    with_repo(shared_core: %w[lib/nothing/**]) do |dir|
      assert findings(dir).any? { |m| m.include?("matches no tracked file") }
    end
  end

  def test_check_refuses_a_malformed_record_scope_and_passes_a_good_one
    with_repo do |dir|
      make_record(dir, "good", scope: %w[lib/a/**], through: 0)
      assert_empty findings(dir).grep(/scope/)
      make_record(dir, "bad", scope: %w[../x/**], through: 0)
      assert findings(dir).any? { |m| m.include?("bad") && m.include?("scope") && m.include?("..") }
    end
  end

  def test_check_passes_on_a_well_formed_declaration
    with_repo(shared_core: %w[lib/base/**], access_control: %w[lib/auth/**]) do |dir|
      assert_empty findings(dir).grep(/shared_core|access_control/)
    end
  end

  def test_change_new_accepts_a_scope
    with_repo do |dir|
      code, out = cli(dir, "change", "new", "x", "--scope", "lib/a/**,lib/b/**")
      assert_equal 0, code, out
      assert_equal %w[lib/a/** lib/b/**], YAML.safe_load_file(File.join(dir, "changes", "x", "metadata.yml"), permitted_classes: [Time, Date])["scope"]
    end
  end

  def test_the_gem_gains_no_dependency
    spec = File.read(File.join(REPO_ROOT, "soft_foundry.gemspec")) if File.exist?(File.join(REPO_ROOT, "soft_foundry.gemspec"))
    skip "no gemspec" unless spec
    refute_match(/add_(runtime_)?dependency/, spec)
  end
end
