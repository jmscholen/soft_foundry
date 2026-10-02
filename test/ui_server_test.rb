# frozen_string_literal: true

require "json"
require "socket"
require_relative "test_helper"

class UIServerTest < Minitest::Test
  include FoundryFixture

  Response = Struct.new(:status, :headers, :body)

  def with_server(**options)
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1", "--title", "First change")
      commit_all(dir, "record c1")
      server = SoftFoundry::UI::Server.new(dir, port: 0, **options)
      port = server.start
      thread = Thread.new { server.serve }
      begin
        yield dir, port, server
      ensure
        server.stop
        thread.join(5)
      end
    end
  end

  # A raw socket, so the test controls every header a browser would set.
  def request(port, line, headers = nil)
    headers ||= { "Host" => "127.0.0.1:#{port}" }
    socket = TCPSocket.new("127.0.0.1", port)
    socket.write("#{line}\r\n#{headers.map { |k, v| "#{k}: #{v}\r\n" }.join}\r\n")
    parse(socket.read)
  ensure
    socket&.close
  end

  def parse(raw)
    head, body = raw.to_s.split("\r\n\r\n", 2)
    lines = head.to_s.split("\r\n")
    status = lines.shift.to_s[/\AHTTP\/1\.1 (\d{3})/, 1].to_i
    Response.new(status, lines.to_h { |l| k, v = l.split(": ", 2); [k.downcase, v] }, body.to_s)
  end

  def get(port, path, extra = {}) = request(port, "GET #{path} HTTP/1.1", { "Host" => "127.0.0.1:#{port}" }.merge(extra))

  def test_serves_the_page_and_its_assets
    with_server do |_dir, port, _server|
      page = get(port, "/")
      assert_equal 200, page.status
      assert_equal "text/html; charset=utf-8", page.headers["content-type"]
      assert_includes page.body, "<title>"
      assert_equal page.body.bytesize, page.headers["content-length"].to_i
      assert_equal "text/css; charset=utf-8", get(port, "/app.css").headers["content-type"]
      script = get(port, "/app.js")
      assert_equal 200, script.status
      assert_equal "text/javascript; charset=utf-8", script.headers["content-type"]
    end
  end

  def test_every_response_carries_the_protective_headers
    with_server do |_dir, port, _server|
      [get(port, "/"), get(port, "/api/changes"), get(port, "/nope"), request(port, "POST / HTTP/1.1")].each do |response|
        csp = response.headers["content-security-policy"]
        assert_includes csp, "default-src 'none'"
        assert_includes csp, "script-src 'self'"
        assert_includes csp, "frame-ancestors 'none'"
        refute_includes csp, "unsafe"
        assert_equal "nosniff", response.headers["x-content-type-options"]
        assert_equal "no-referrer", response.headers["referrer-policy"]
        assert_equal "no-store", response.headers["cache-control"]
        assert_equal "close", response.headers["connection"]
        refute response.headers.keys.any? { |k| k.start_with?("access-control-") }
      end
    end
  end

  def test_api_returns_the_snapshot_as_json
    with_server do |_dir, port, _server|
      workflow = get(port, "/api/workflow")
      assert_equal "application/json; charset=utf-8", workflow.headers["content-type"]
      assert_equal 16, JSON.parse(workflow.body)["phases"].size
      board = JSON.parse(get(port, "/api/changes").body)
      assert_equal ["c1"], board["changes"].map { |c| c["slug"] }
      change = JSON.parse(get(port, "/api/change?slug=c1").body)
      assert_equal "First change", change["title"]
      assert_equal 16, change["gates"].size
    end
  end

  def test_a_slug_with_a_slash_is_addressed_by_query
    with_server do |dir, port, _server|
      cli(dir, "change", "new", "team/alpha", "--title", "Nested")
      assert_equal "Nested", JSON.parse(get(port, "/api/change?slug=team%2Falpha").body)["title"]
      assert_equal "Nested", JSON.parse(get(port, "/api/change?slug=team/alpha").body)["title"]
    end
  end

  def test_head_returns_headers_without_a_body
    with_server do |_dir, port, _server|
      response = request(port, "HEAD / HTTP/1.1")
      assert_equal 200, response.status
      assert_operator response.headers["content-length"].to_i, :>, 0
      assert_empty response.body
    end
  end

  # Read-only: nothing but GET and HEAD is answered.
  def test_other_methods_are_refused
    with_server do |_dir, port, _server|
      %w[POST PUT DELETE PATCH OPTIONS].each do |verb|
        response = request(port, "#{verb} /api/changes HTTP/1.1")
        assert_equal 405, response.status, verb
        assert_equal "GET, HEAD", response.headers["allow"]
      end
    end
  end

  # A page on another site can point a hostname at 127.0.0.1 (DNS
  # rebinding); the browser then sends that hostname as Host.
  def test_a_host_header_that_is_not_this_server_is_refused
    with_server do |_dir, port, _server|
      assert_equal 403, request(port, "GET / HTTP/1.1", { "Host" => "evil.example:#{port}" }).status
      assert_equal 403, request(port, "GET / HTTP/1.1", { "Host" => "127.0.0.1:#{port + 1}" }).status
      assert_equal 403, request(port, "GET / HTTP/1.1", { "Host" => "127.0.0.1" }).status
      assert_equal 403, request(port, "GET / HTTP/1.1", {}).status
      assert_equal 200, request(port, "GET / HTTP/1.1", { "Host" => "localhost:#{port}" }).status
      assert_equal 200, request(port, "GET / HTTP/1.1", { "host" => "LOCALHOST:#{port}" }).status
    end
  end

  # The data is for this page only. The page itself carries nothing
  # about the repository, so a link to it from another site still opens.
  def test_a_request_for_data_that_another_site_made_is_refused
    with_server do |_dir, port, _server|
      %w[/api/changes /api/workflow /api/change?slug=c1 /api/nope].each do |path|
        assert_equal 403, get(port, path, "Sec-Fetch-Site" => "cross-site").status, path
        assert_equal 403, get(port, path, "Sec-Fetch-Site" => "same-site").status, path
      end
      assert_equal 200, get(port, "/api/changes", "Sec-Fetch-Site" => "same-origin").status
      assert_equal 200, get(port, "/api/changes", "Sec-Fetch-Site" => "none").status
      assert_equal 200, get(port, "/", "Sec-Fetch-Site" => "cross-site").status
      refute_includes get(port, "/", "Sec-Fetch-Site" => "cross-site").body, "First change"
    end
  end

  # The route table is exact. Nothing in the URL names a file.
  def test_only_the_six_routes_exist
    with_server do |dir, port, _server|
      File.write(File.join(dir, "secret.txt"), "s3cret")
      ["/../secret.txt", "/secret.txt", "/app.js/..", "/app.js/", "//app.js", "/assets/index.html", "/index.html", "/%2e%2e/secret.txt",
       "/api", "/api/changes/", "/api/change/c1", "/favicon.ico"].each do |path|
        response = get(port, path)
        assert_equal 404, response.status, path
        refute_includes response.body, "s3cret"
      end
      assert_equal 200, get(port, "/?x=1").status
    end
  end

  def test_an_unknown_or_hostile_slug_is_not_found
    with_server do |_dir, port, _server|
      assert_equal 404, get(port, "/api/change?slug=nope").status
      assert_equal 404, get(port, "/api/change?slug=../../etc").status
      assert_equal 404, get(port, "/api/change?slug=c1%00").status
      assert_equal 400, get(port, "/api/change").status
      assert_equal 400, get(port, "/api/change?slug=").status
      assert_equal 400, get(port, "/api/change?slug=%zz").status
    end
  end

  def test_malformed_and_oversized_requests_are_refused
    with_server do |_dir, port, _server|
      assert_equal 400, request(port, "GARBAGE").status
      assert_equal 400, request(port, "GET http://127.0.0.1:#{port}/ HTTP/1.1").status
      assert_equal 400, request(port, "GET / HTTP/9.9").status
      assert_equal 431, get(port, "/", "X-Padding" => "a" * 9000).status
      assert_equal 200, get(port, "/").status, "the server is still answering"
    end
  end

  # A connection that never sends a request is dropped, and does not hold
  # up anyone else while it waits.
  def test_a_silent_connection_is_dropped_without_blocking_others
    with_server(read_timeout: 0.5) do |_dir, port, _server|
      silent = TCPSocket.new("127.0.0.1", port)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_equal 200, get(port, "/").status
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.4
      assert_equal 408, parse(silent.read).status
    ensure
      silent&.close
    end
  end

  # Record text is data. It is returned JSON-encoded with a JSON content
  # type, so a browser never interprets it as markup.
  def test_record_text_is_returned_as_json_not_markup
    with_server do |dir, port, _server|
      cli(dir, "change", "new", "xss", "--title", "<script>alert(1)</script>")
      response = get(port, "/api/change?slug=xss")
      assert_equal "application/json; charset=utf-8", response.headers["content-type"]
      assert_equal "<script>alert(1)</script>", JSON.parse(response.body)["title"]
    end
  end

  def test_a_change_that_cannot_be_read_is_an_error_response_not_a_crash
    with_server do |dir, port, _server|
      cli(dir, "change", "new", "broken", "--title", "x")
      File.write(File.join(dir, "changes", "broken", "metadata.yml"), "change: [unterminated\n")
      response = get(port, "/api/change?slug=broken")
      assert_equal 500, response.status
      error = JSON.parse(response.body)["error"]
      assert_includes error, "changes/broken/metadata.yml"
      refute_includes response.body, dir
      assert_equal 200, get(port, "/api/change?slug=c1").status
    end
  end

  # Several tabs polling must not each start a gate run: an answer is
  # reused for a short time.
  def test_api_answers_are_reused_briefly
    now = 100.0
    with_server(clock: -> { now }, ttl: 2) do |dir, port, _server|
      before = JSON.parse(get(port, "/api/change?slug=c1").body)
      assert_equal "pending", before["gates"].first["state"]
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
      complete_phase!(record, "intake", sha: head(dir))

      now = 101.0
      assert_equal "pending", JSON.parse(get(port, "/api/change?slug=c1").body)["gates"].first["state"]
      now = 102.5
      assert_equal "pass", JSON.parse(get(port, "/api/change?slug=c1").body)["gates"].first["state"]
    end
  end

  def test_it_listens_on_loopback_only
    with_server do |_dir, port, server|
      assert_equal port, server.port
      assert_equal "127.0.0.1", server.address
    end
  end

  def test_a_port_in_use_is_a_target_error
    with_server do |dir, port, _server|
      error = assert_raises(SoftFoundry::TargetError) { SoftFoundry::UI::Server.new(dir, port: port).start }
      assert_includes error.message, "port #{port} is already in use"
    end
  end

  def test_stop_ends_serve
    with_fixture_repo do |dir|
      server = SoftFoundry::UI::Server.new(dir, port: 0)
      server.start
      thread = Thread.new { server.serve }
      server.stop
      assert thread.join(5), "serve returns once stopped"
      server.stop
    end
  end
end
