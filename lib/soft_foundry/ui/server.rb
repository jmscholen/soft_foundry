# frozen_string_literal: true

require "digest"
require "json"
require "openssl"
require "securerandom"
require "socket"
require "uri"
require_relative "../errors"
require_relative "../git"
require_relative "../control_plane"
require_relative "../change_index"
require_relative "../snapshot"
require_relative "../processes"

module SoftFoundry
  module UI
    # A read-only HTTP server for the workflow and change records of the
    # Soft Foundry repositories on this machine, for a browser on the same
    # machine. It listens on the loopback address only, answers GET and
    # HEAD on eight fixed routes, and never takes a file name from a
    # request. Every request reads the control plane and the records
    # afresh, so the page follows edits.
    #
    # It knows the repository it was started in, any added at start, and
    # any in which a session or command is found running. A request names
    # a repository by the id the server gave it, never by a path. Data is
    # answered only to a request carrying the token in the link the
    # command printed.
    class Server
      ADDRESS = "127.0.0.1"
      ASSETS = File.expand_path("assets", __dir__)
      STATIC = {
        "/" => ["index.html", "text/html; charset=utf-8"],
        "/app.css" => ["app.css", "text/css; charset=utf-8"],
        "/app.js" => ["app.js", "text/javascript; charset=utf-8"]
      }.freeze
      JSON_TYPE = "application/json; charset=utf-8"
      ROUTES = %w[/api/workflow /api/changes /api/change /api/processes /api/repositories].freeze
      REQUEST_LINE = %r{\A([A-Z]+) (/\S*) HTTP/1\.[01]\z}
      MAX_HEADER_BYTES = 8192
      MAX_CONNECTIONS = 16
      TOKEN_HEADER = "x-soft-foundry-token"
      REASONS = { 200 => "OK", 400 => "Bad Request", 401 => "Unauthorized", 403 => "Forbidden", 404 => "Not Found", 405 => "Method Not Allowed",
                  408 => "Request Timeout", 431 => "Request Header Fields Too Large", 500 => "Internal Server Error",
                  503 => "Service Unavailable" }.freeze
      # Nothing inline, nothing remote, no framing, no form targets: the
      # page may load its own two files and call its own API, and that is all.
      HEADERS = {
        "Content-Security-Policy" => "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; " \
                                     "base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
        "X-Content-Type-Options" => "nosniff",
        "Referrer-Policy" => "no-referrer",
        "Cache-Control" => "no-store",
        "Connection" => "close"
      }.freeze

      attr_reader :port, :token

      # `ttl` is how long an API answer is reused, so several tabs polling
      # do not each start a gate run; `read_timeout` is how long a
      # connection may take to send its request.
      def initialize(root, port: 0, ttl: 2, read_timeout: 2, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, processes: nil,
                     token: SecureRandom.urlsafe_base64(24), repos: [])
        @root = real(root)
        @token = token.to_s
        @registry = Mutex.new
        @repos = {}
        register(@root)
        repos.each do |path|
          raise TargetError, "#{path} has no .ai/workflow.yml; --repo takes a repository with a Soft Foundry control plane" unless register(real(path))
        end
        @requested_port = port
        @ttl = ttl
        @read_timeout = read_timeout
        @clock = clock
        @processes = processes || ->(dir) { Processes.new(dir) }
        @cache = {}
        @lock = Mutex.new
        @connections = 0
        @waiting = {}
        @counter = Mutex.new
      end

      def address = ADDRESS

      # The link to open: the token rides in the fragment, which a browser
      # keeps to itself, and the page sends it back as a header.
      def url = "http://#{ADDRESS}:#{port}/#token=#{token}"

      # Binds the listener and returns the port (the one asked for, or the
      # one the system chose for port 0).
      def start
        @listener = TCPServer.new(ADDRESS, @requested_port)
        @port = @listener.addr[1]
      rescue Errno::EADDRINUSE
        raise TargetError, "port #{@requested_port} is already in use; pass another --port, or omit it to let the system choose"
      rescue Errno::EACCES
        raise TargetError, "port #{@requested_port} needs privileges this process does not have; pass a --port above 1023"
      end

      # Answers requests until `stop`. Each connection gets a thread, so
      # one that sends nothing cannot hold up the rest, and when every slot
      # is taken the connection that has waited longest without sending a
      # request gives up its slot to the new one.
      def serve
        loop do
          client = @listener.accept
          Thread.new(client) { |socket| handle(socket) }
        end
      rescue IOError, Errno::EBADF
        nil
      end

      def stop
        @listener&.close unless @listener&.closed?
      end

      # The answer to one request as [status, content type, body, extra
      # headers]. No socket is involved, and nothing in `target` is used as
      # a path on disk.
      def respond(verb, target, headers)
        return error(405, "this server is read-only; only GET and HEAD are answered", "Allow" => "GET, HEAD") unless %w[GET HEAD].include?(verb)
        return error(403, "the Host header does not name this server") unless own_host?(headers["host"])
        path, query = target.split("?", 2)
        # The page itself says nothing about the repository, and a link to
        # it from elsewhere must open. The data is only for this page.
        if (asset = STATIC[path])
          return [200, asset[1], File.binread(File.join(ASSETS, asset[0])), {}]
        end
        return error(403, "the request came from another site") unless own_site?(headers["sec-fetch-site"])
        return error(404, "no such page") unless ROUTES.include?(path)
        return error(401, "this needs the link soft-foundry ui printed when it started; open that link again") unless authorized?(headers[TOKEN_HEADER])
        return error(400, "the query string is not valid") if query.to_s.match?(/%(?![0-9A-Fa-f]{2})/)
        params = URI.decode_www_form(query.to_s).to_h.transform_values { |value| value.to_s.scrub("?") }
        return cached("processes") { running } if path == "/api/processes"
        return cached("repositories") { repositories } if path == "/api/repositories"

        id, root = repository(params["repo"])
        return error(404, "no such repository") unless root
        case path
        when "/api/workflow" then cached("workflow:#{id}") { snapshot(root).workflow }
        when "/api/changes" then cached("changes:#{id}") { snapshot(root).board }
        when "/api/change" then change(id, root, params["slug"].to_s)
        end
      end

      private

      def own_host?(host) = ["#{ADDRESS}:#{port}", "localhost:#{port}"].include?(host.to_s.downcase)

      # Browsers say whether a request came from this page (same-origin),
      # from the address bar (none), or from somewhere else. Clients that
      # do not send the header are not browsers.
      def own_site?(site) = site.nil? || %w[same-origin none].include?(site)

      # The token is compared in constant time and only ever read from the
      # header: a link someone pastes elsewhere does not carry it.
      def authorized?(given)
        given = given.to_s
        given.bytesize == @token.bytesize && OpenSSL.fixed_length_secure_compare(given, @token)
      end

      def change(id, root, slug)
        return error(400, "name a change with ?slug=") if slug.empty?
        # Only a slug that repository's own listing returned is ever loaded.
        return error(404, "no such change") unless index(root).slugs.include?(slug)
        cached("change:#{id}:#{slug}") { snapshot(root).change(slug) }
      end

      # A fresh control plane per answer: a long-lived process must not
      # serve a workflow it read at startup.
      def snapshot(root)
        plane = ControlPlane.new(root)
        git = Git.new(root)
        Snapshot.new(root, plane: plane, git: git, index: ChangeIndex.new(root, plane: plane, git: git))
      end

      def index(root) = ChangeIndex.new(root, plane: ControlPlane.new(root), git: Git.new(root))

      def real(path)
        File.realpath(path)
      rescue SystemCallError
        File.expand_path(path)
      end

      def repo_id(root) = Digest::SHA256.hexdigest(root)[0, 12]

      # Remembers a repository and returns its id, or nil when the
      # directory has no control plane. Once known, a repository stays
      # known for as long as the server runs, so a page open on it does
      # not lose it when its last session closes.
      def register(root)
        return nil unless root && File.file?(File.join(root, ".ai", "workflow.yml"))
        @registry.synchronize { @repos[repo_id(root)] ||= root }
        repo_id(root)
      end

      # The id and path a request's `repo` names: the home repository when
      # it names none, nothing when it names one the server never issued.
      def repository(id)
        return [repo_id(@root), @root] if id.nil?
        root = @registry.synchronize { @repos[id] }
        root ? [id, root] : nil
      end

      # What is running, with each entry's repository as an id. This is
      # also how repositories are found: one with a session or a command
      # in it becomes known here.
      def running
        data = @processes.call(@root).snapshot(roots: @registry.synchronize { @repos.values }, with_roots: true)
        %w[processes sessions recorded_runs].each do |key|
          Array(data[key]).each { |entry| entry["repo"] = register(entry.delete("root")) }
        end
        data
      end

      def repositories
        running
        list = @registry.synchronize { @repos.to_a }.map do |id, root|
          about = begin
            snapshot(root).overview
          rescue StandardError => e
            { "open" => 0, "closed" => 0, "changes" => [], "error" => e.message.gsub("#{root}/", "") }
          end
          { "id" => id, "name" => Snapshot.plain(File.basename(root)), "path" => Processes.display(root), "home" => root == @root }.merge(about)
        end
        { "version" => Snapshot::VERSION, "generated_at" => Time.now.utc.iso8601,
          "repositories" => list.sort_by { |repo| [repo["home"] ? 0 : 1, repo["name"].to_s.downcase, repo["id"]] } }
      end

      # One answer at a time is computed, so concurrent requests wait for
      # it rather than each starting their own git subprocesses. Errors
      # are not kept.
      def cached(key)
        @lock.synchronize do
          at, body = @cache[key]
          if body.nil? || @clock.call - at >= @ttl
            body = JSON.generate(yield)
            @cache[key] = [@clock.call, body]
          end
          [200, JSON_TYPE, body, {}]
        end
      rescue StandardError => e
        roots = @registry.synchronize { @repos.values }
        error(500, "could not read this from the repository: #{roots.reduce(e.message) { |text, root| text.gsub("#{root}/", '') }}")
      end

      def error(status, message, extra = {})
        [status, JSON_TYPE, JSON.generate("error" => message), extra]
      end

      def handle(socket)
        return write(socket, "GET", error(503, "too many connections")) unless admit(socket)
        begin
          verb, target, headers, problem = begin
            read_request(socket)
          ensure
            @counter.synchronize { @waiting.delete(socket) }
          end
          write(socket, verb || "GET", problem || respond(verb, target, headers))
        ensure
          @counter.synchronize { @connections -= 1 }
        end
      rescue StandardError
        nil
      ensure
        socket.close unless socket.closed?
      end

      # At the limit, the oldest connection still waiting to send its
      # request is closed to make room. Only when every slot is busy
      # answering is the newcomer turned away.
      def admit(socket)
        @counter.synchronize do
          if @connections >= MAX_CONNECTIONS
            idle = @waiting.keys.first or return false
            @waiting.delete(idle)
            idle.close unless idle.closed?
          end
          @connections += 1
          @waiting[socket] = true
        end
        true
      end

      # Reads up to the end of the headers and no further: a body is never
      # read. Returns [verb, target, headers, nil] or [nil, nil, nil, error].
      def read_request(socket)
        buffer = +""
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @read_timeout
        until buffer.include?("\r\n\r\n")
          return [nil, nil, nil, error(431, "request headers are too large")] if buffer.bytesize > MAX_HEADER_BYTES
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          return [nil, nil, nil, error(408, "no request was received in time")] if remaining <= 0 || !socket.wait_readable(remaining)
          chunk = socket.read_nonblock(4096, exception: false)
          next if chunk == :wait_readable
          return [nil, nil, nil, error(400, "the request was not complete")] if chunk.nil?
          buffer << chunk
        end
        head = buffer.split("\r\n\r\n", 2).first
        return [nil, nil, nil, error(431, "request headers are too large")] if head.bytesize > MAX_HEADER_BYTES
        lines = head.split("\r\n")
        match = REQUEST_LINE.match(lines.shift.to_s) or return [nil, nil, nil, error(400, "the request line is not valid")]
        headers = lines.to_h do |line|
          name, value = line.split(":", 2)
          [name.to_s.strip.downcase, value.to_s.strip]
        end
        [match[1], match[2], headers, nil]
      end

      def write(socket, verb, response)
        status, type, body, extra = response
        head = ["HTTP/1.1 #{status} #{REASONS.fetch(status)}", "Content-Type: #{type}", "Content-Length: #{body.bytesize}"]
        HEADERS.merge(extra).each { |name, value| head << "#{name}: #{value}" }
        socket.write("#{head.join("\r\n")}\r\n\r\n")
        socket.write(body) unless verb == "HEAD"
      end
    end
  end
end
