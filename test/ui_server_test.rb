# frozen_string_literal: true

require "json"
require "socket"
require_relative "test_helper"

class UIServerTest < Minitest::Test
  include FoundryFixture

  Response = Struct.new(:status, :headers, :body)
  TOKEN = "test-token"
  WITH_TOKEN = { "X-Soft-Foundry-Token" => TOKEN }.freeze

  def with_server(**options)
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1", "--title", "First change")
      commit_all(dir, "record c1")
      server = SoftFoundry::UI::Server.new(dir, port: 0, token: TOKEN, **options)
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

  # A request as the page makes it: with the token the server's link carried.
  def get(port, path, extra = {}) = request(port, "GET #{path} HTTP/1.1", { "Host" => "127.0.0.1:#{port}" }.merge(WITH_TOKEN).merge(extra))

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

  Listing = Struct.new(:data) do
    def snapshot(**) = Marshal.load(Marshal.dump(data))
  end

  # The data is for whoever was given the link. The page's own files say
  # nothing about any repository and are served without it.
  def test_data_needs_the_token_the_link_carried
    with_server do |_dir, port, server|
      %w[/api/changes /api/workflow /api/processes /api/repositories /api/change?slug=c1].each do |path|
        assert_equal 401, request(port, "GET #{path} HTTP/1.1", { "Host" => "127.0.0.1:#{port}" }).status, path
        assert_equal 401, get(port, path, "X-Soft-Foundry-Token" => "wrong").status, path
        assert_equal 401, get(port, "#{path}#{path.include?('?') ? '&' : '?'}token=#{TOKEN}", "X-Soft-Foundry-Token" => "").status, "the token is not accepted in the address"
        assert_equal 200, get(port, path).status, path
      end
      assert_equal 200, request(port, "GET / HTTP/1.1").status
      assert_equal 200, request(port, "GET /app.js HTTP/1.1").status
      refute_includes request(port, "GET /api/changes HTTP/1.1", { "Host" => "127.0.0.1:#{port}" }).body, "First change"
      assert_equal "http://127.0.0.1:#{port}/#token=#{TOKEN}", server.url
    end
  end

  def test_a_token_is_made_up_for_each_server
    with_fixture_repo do |dir|
      a = SoftFoundry::UI::Server.new(dir, port: 0).token
      b = SoftFoundry::UI::Server.new(dir, port: 0).token
      refute_equal a, b
      assert_operator a.length, :>=, 32
      assert_match(/\A[\w-]+\z/, a)
    end
  end

  def with_other_repository
    with_fixture_repo do |other|
      sh(other, "git", "checkout", "-qb", "change/elsewhere")
      cli(other, "change", "new", "elsewhere", "--title", "Work in another repository")
      cli(other, "change", "new", "shipped", "--title", "Done")
      plane = SoftFoundry::ControlPlane.new(other)
      SoftFoundry::ChangeRecord.new(other, "shipped", control_plane: plane).close!
      Dir.mktmpdir("not-governed") { |plain| yield File.realpath(other), File.realpath(plain) }
    end
  end

  # One page for every Soft Foundry repository with something going on:
  # the one the server was started in, and any a session or command is in.
  def test_repositories_are_the_home_one_and_those_with_something_running
    with_other_repository do |other, plain|
      running = { "version" => 1, "processes" => [{ "pid" => 9, "command" => "ci", "root" => plain }],
                  "sessions" => [{ "pid" => 7, "shell" => "claude", "change" => "elsewhere", "root" => other }], "recorded_runs" => [] }
      with_server(processes: ->(_root) { Listing.new(running) }) do |dir, port, _server|
        list = JSON.parse(get(port, "/api/repositories").body)["repositories"]
        assert_equal 2, list.size, "a directory with no control plane is not a repository"
        home = list.find { |r| r["home"] }
        there = list.find { |r| !r["home"] }
        assert_equal File.basename(dir), home["name"]
        assert_equal File.basename(other), there["name"]
        assert_match(/\A[0-9a-f]{12}\z/, there["id"])
        assert_equal 1, there["open"]
        assert_equal 1, there["closed"]
        assert_equal [{ "slug" => "elsewhere", "title" => "Work in another repository", "status" => "intake", "current_phase" => "intake" }], there["changes"]
        assert_equal 1, home["open"]

        board = JSON.parse(get(port, "/api/changes?repo=#{there['id']}").body)
        assert_equal %w[elsewhere shipped], board["changes"].map { |c| c["slug"] }
        assert_equal ["c1"], JSON.parse(get(port, "/api/changes").body)["changes"].map { |c| c["slug"] }, "no repo means the home repository"
        assert_equal ["c1"], JSON.parse(get(port, "/api/changes?repo=#{home['id']}").body)["changes"].map { |c| c["slug"] }
        assert_equal "Work in another repository", JSON.parse(get(port, "/api/change?repo=#{there['id']}&slug=elsewhere").body)["title"]
        assert_equal 404, get(port, "/api/change?repo=#{there['id']}&slug=c1").status, "a slug belongs to its repository"
        assert_equal 16, JSON.parse(get(port, "/api/workflow?repo=#{there['id']}").body)["phases"].size

        data = JSON.parse(get(port, "/api/processes").body)
        assert_equal there["id"], data["sessions"].first["repo"]
        assert_nil data["processes"].first["repo"]
        # Where a repository is on disk is said once, in the list of
        # repositories, and nowhere else; a plain directory never.
        assert_equal other, there["path"]
        text = JSON.generate(data) + get(port, "/api/changes?repo=#{there['id']}").body
        refute_includes text + get(port, "/api/repositories").body, "\"root\""
        refute_includes text, other
        refute_includes text + get(port, "/api/repositories").body, plain
      end
    end
  end

  # A repository is named by an id the server handed out, never by a path.
  def test_a_request_cannot_name_a_repository_by_path
    with_other_repository do |other, _plain|
      with_server do |_dir, port, _server|
        ["000000000000", other, "..", "%2Fetc", ""].each do |repo|
          assert_equal 404, get(port, "/api/changes?repo=#{URI.encode_www_form_component(repo)}").status, repo.inspect
        end
        refute_includes get(port, "/api/repositories").body, File.basename(other), "nothing is running there, so it is not known"
      end
    end
  end

  def test_repositories_can_be_added_when_the_server_starts
    with_other_repository do |other, plain|
      with_server(repos: [other]) do |_dir, port, _server|
        names = JSON.parse(get(port, "/api/repositories").body)["repositories"].map { |r| r["name"] }
        assert_includes names, File.basename(other)
      end
      with_fixture_repo do |dir|
        error = assert_raises(SoftFoundry::TargetError) { SoftFoundry::UI::Server.new(dir, port: 0, repos: [plain]) }
        assert_includes error.message, "has no .ai/workflow.yml"
      end
    end
  end

  def test_api_returns_running_processes
    data = { "version" => 1, "processes" => [{ "pid" => 7, "command" => "ci" }], "recorded_runs" => [] }
    with_server(processes: ->(_root) { Listing.new(data) }) do |_dir, port, _server|
      response = get(port, "/api/processes")
      assert_equal 200, response.status
      assert_equal "application/json; charset=utf-8", response.headers["content-type"]
      assert_equal data.merge("processes" => [{ "pid" => 7, "command" => "ci", "repo" => nil }]), JSON.parse(response.body)
      assert_equal 403, get(port, "/api/processes", "Sec-Fetch-Site" => "cross-site").status
      assert_equal 405, request(port, "POST /api/processes HTTP/1.1").status
      assert_equal 404, get(port, "/api/processes/7").status
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
  def test_only_the_listed_routes_exist
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

  # Found by ATTACK-005: enough silent connections used to fill every
  # slot, and real requests were answered 503 until the silent ones timed
  # out. The connection that has waited longest without sending a request
  # now gives up its slot. What is asserted is that the requests are
  # answered before the silent connections could have timed out (the read
  # timeout), not a fixed number of seconds: under load the board alone
  # took over two seconds, which is what made this test flaky.
  def test_silent_connections_cannot_crowd_out_a_request
    with_server(read_timeout: 8) do |_dir, port, _server|
      silent = Array.new(40) { TCPSocket.new("127.0.0.1", port) }
      sleep 0.2
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_equal 200, get(port, "/").status
      assert_equal 200, get(port, "/api/changes").status
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 8
    ensure
      Array(silent).each(&:close)
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
