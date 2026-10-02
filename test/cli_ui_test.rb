# frozen_string_literal: true

require_relative "test_helper"

class CLIUiTest < Minitest::Test
  include FoundryFixture

  # Stands in for the server so the command returns instead of serving.
  class FakeServer
    attr_reader :calls

    def initialize(interrupt: false)
      @calls = []
      @interrupt = interrupt
    end

    def start = (@calls << :start) && 4321
    def stop = @calls << :stop

    def serve
      @calls << :serve
      raise Interrupt if @interrupt
    end
  end

  def ui(dir, *args, server: FakeServer.new)
    built = []
    factory = lambda do |root, port:|
      built << [root, port]
      server
    end
    out = StringIO.new
    err = StringIO.new
    code = SoftFoundry::CLI.new(["ui", *args], out: out, err: err, root: dir, ui_server: factory).run
    [code, out.string + err.string, built, server]
  end

  def test_ui_says_where_it_is_serving_and_that_it_is_read_only
    with_fixture_repo do |dir|
      code, out, built, server = ui(dir)
      assert_equal 0, code, out
      assert_equal "ui: serving http://127.0.0.1:4321/ (read-only; press Ctrl-C to stop)\nui: stopped\n", out
      assert_equal [[File.expand_path(dir), 0]], built
      assert_equal %i[start serve stop], server.calls
    end
  end

  def test_ui_passes_the_requested_port
    with_fixture_repo do |dir|
      _, _, built, = ui(dir, "--port", "8123")
      assert_equal 8123, built.first.last
    end
  end

  def test_ctrl_c_stops_the_server_and_exits_cleanly
    with_fixture_repo do |dir|
      code, out, _, server = ui(dir, server: FakeServer.new(interrupt: true))
      assert_equal 0, code
      assert_includes out, "ui: stopped"
      assert_equal :stop, server.calls.last
    end
  end

  def test_a_bad_port_or_option_is_refused_before_anything_starts
    with_fixture_repo do |dir|
      ["abc", "-1", "70000", "80.5"].each do |port|
        code, out, built, = ui(dir, "--port", port)
        assert_equal 1, code, port
        assert_includes out, "--port expects a whole number from 0 to 65535"
        assert_empty built
      end
      code, out, built, = ui(dir, "--host", "0.0.0.0")
      assert_equal 1, code
      assert_includes out, "unknown option(s): --host 0.0.0.0"
      assert_empty built
    end
  end

  def test_ui_needs_a_control_plane
    with_target_repo do |dir|
      code, out, built, = ui(dir)
      assert_equal 1, code
      assert_includes out, "no .ai/workflow.yml here; run `soft-foundry init` first"
      assert_empty built
    end
  end

  def test_help_describes_ui
    with_fixture_repo do |dir|
      _, out = cli(dir)
      assert_includes out, "soft-foundry ui [--port N]"
      assert_includes out, "read-only"
    end
  end
end
