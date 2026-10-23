# frozen_string_literal: true

require "json"
require "socket"
require_relative "lifecycle_fixture"

# The page shows a released record by the word "released" and its
# open-item count, lists open items in a table with header cells, and
# puts record text on the page only as text (WCAG 1.4.1, 1.3.1, 4.1.2).
class UIReleasedTest < Minitest::Test
  include FinishedFixture

  ASSETS = File.expand_path("../lib/soft_foundry/ui/assets", __dir__)
  TOKEN = "test-token"

  def script = SoftFoundry.read_text(File.join(ASSETS, "app.js"))
  def styles = SoftFoundry.read_text(File.join(ASSETS, "app.css"))

  def get(port, path)
    socket = TCPSocket.new("127.0.0.1", port)
    socket.write("GET #{path} HTTP/1.1\r\nHost: 127.0.0.1:#{port}\r\nX-Soft-Foundry-Token: #{TOKEN}\r\n\r\n")
    raw = socket.read
    JSON.parse(raw.split("\r\n\r\n", 2).last)
  ensure
    socket&.close
  end

  def with_released_server
    with_finished_record do |dir, record|
      record.update_metadata do |m|
        m["status"] = "released"
        m["release"] = { "at" => "2026-10-24T09:00:00Z", "commit" => head(dir),
                         "items" => [{ "id" => "GO-1", "description" => "<script>alert(1)</script> confirm" }, { "id" => "GO-2", "description" => "second", "discharged_at" => "2026-10-25T09:00:00Z", "discharge_note" => "seen" }] }
      end
      server = SoftFoundry::UI::Server.new(dir, port: 0, token: TOKEN)
      port = server.start
      thread = Thread.new { server.serve }
      begin
        yield port
      ensure
        server.stop
        thread.join(5)
      end
    end
  end

  def test_the_served_data_carries_the_status_the_count_and_the_items
    with_released_server do |port|
      board = get(port, "/api/changes")
      row = board["changes"].find { |c| c["slug"] == "c1" }
      assert_equal "released", row["status"]
      assert_equal 1, row["open_items"]
      assert_equal false, row["closed"]
      change = get(port, "/api/change?slug=c1")
      assert_equal true, change["released"]
      assert_equal %w[GO-1 GO-2], change["release"]["items"].map { |i| i["id"] }
      assert_includes change["release"]["items"].first["description"], "<script>"
    end
  end

  def test_the_page_script_names_released_with_the_count_in_words
    assert_includes script, "released"
    assert_match(/open item/, script)
    assert_includes script, "Released"
  end

  def test_open_items_are_a_table_with_header_cells_and_record_text_stays_text
    section = script[/function releaseSection.*?\n  }\n/m]
    refute_nil section, "a releaseSection function builds the released items"
    assert_includes section, '"table"'
    assert_includes section, 'scope: "col"'
    assert_includes section, 'el("th"'
    assert_includes section, "caption"
    assert_includes section, "text:"
    refute_match(/innerHTML/, section)
  end

  def test_released_is_not_conveyed_by_colour_alone
    # A flag with words, and a section heading; colour is only a second signal.
    assert_match(/flags\.push\(\["Released: /, script)
    assert_match(/boardSection\("Released"/, script)
  end

  def test_new_styling_uses_the_existing_tone_tokens
    refute_match(/#[0-9a-fA-F]{3,8}\b/, styles[/\.release[^{]*\{[^}]*\}/m].to_s, "released styling must reuse the tone variables, not new colours")
  end
end
