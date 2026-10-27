# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `change new --type TYPE --risk RISK`: recorded at creation, validated
# against one vocabulary, refused before anything is written.
class CliChangeNewOptionsTest < Minitest::Test
  include LifecycleFixture

  def meta(dir, slug) = YAML.safe_load_file(File.join(dir, "changes", slug, "metadata.yml"))

  def test_type_and_risk_are_recorded
    with_fixture_repo do |dir|
      code, out, err = run_cli(dir, "change", "new", "x", "--type", "fix", "--risk", "low")
      assert_equal 0, code, err + out
      assert_equal "fix", meta(dir, "x")["type"]
      assert_equal "low", meta(dir, "x")["risk"]
      assert_includes File.read(File.join(dir, "changes/x/metadata.yml")), "low | medium | high", "template comments survive"
    end
  end

  def test_omitted_flags_keep_the_placeholders
    with_fixture_repo do |dir|
      code, = run_cli(dir, "change", "new", "x", "--type", "chore")
      assert_equal 0, code
      assert_equal "chore", meta(dir, "x")["type"]
      assert_equal "TBD", meta(dir, "x")["risk"]
      run_cli(dir, "change", "new", "y")
      assert_equal "TBD", meta(dir, "y")["type"]
    end
  end

  def test_bad_values_are_refused_with_nothing_created
    with_fixture_repo do |dir|
      [["--type", "Fix"], ["--type", " fix"], ["--type", "fix "], ["--type", ""], ["--type", "bogus"], ["--risk", "HIGH"], ["--risk", "extreme"], ["--risk", ""]].each do |args|
        code, out, err = run_cli(dir, "change", "new", "x", *args)
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, args.inspect
        assert_includes out + err, args.first, args.inspect
        assert_match(/feature, fix, refactor, \w+, infrastructure, security, chore|low, medium, high/, out + err)
        refute File.exist?(File.join(dir, "changes", "x")), "no directory for #{args.inspect}"
      end
    end
  end

  def test_unsafe_slugs_are_refused_before_any_path_is_built
    with_fixture_repo do |dir|
      ["../x", "/abs", "a\0b", "a/../b", "-x"].each do |slug|
        code, = run_cli(dir, "change", "new", slug, "--type", "fix")
        refute_equal 0, code, slug.inspect
      end
      refute File.exist?(File.join(dir, "x"))
    end
  end

  def test_high_risk_on_a_non_gated_track_is_refused
    with_fixture_repo do |dir|
      code, out, err = run_cli(dir, "change", "new", "x", "--risk", "high", "--track", "iterative")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/gated/, out + err)
      refute File.exist?(File.join(dir, "changes", "x"))
      code, = run_cli(dir, "change", "new", "z", "--risk", "high")
      assert_equal 0, code
    end
  end

  def test_the_vocabulary_has_one_source_and_check_lints_it
    assert_equal 7, SoftFoundry::ChangeRecord::TYPES.size
    assert_equal %w[low medium high], SoftFoundry::ChangeRecord::RISKS
    with_fixture_repo do |dir|
      code, out, = run_cli(dir, "check")
      assert_equal 0, code, out
      path = File.join(dir, ".ai/templates/change/metadata.yml")
      File.write(path, File.read(path).sub("feature | fix | refactor", "feature | fix | tweak | refactor"))
      code, out, err = run_cli(dir, "check")
      refute_equal 0, code
      assert_match(/type/, out + err)
    end
  end
end
