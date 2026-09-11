# frozen_string_literal: true

require "json"
require "open3"

module SoftFoundry
  # Turns "a human verified this in the real world" from an unfalsifiable
  # assertion in a commit message into a checkable precondition: a request
  # posted as a PR comment, and a reply matching CONFIRMED: <id> as the only
  # thing that counts as confirmation. `change close` is the enforcement
  # point - it will not discharge an item without a matching id here.
  class PrDischarge
    CONFIRM = /CONFIRMED:\s*([A-Za-z0-9_,\-\s]+)/i

    def initialize(root, fetcher: nil, poster: nil)
      @root = root
      @fetcher = fetcher || method(:real_comments)
      @poster = poster || method(:real_comment)
    end

    # ids confirmed by any PR comment matching CONFIRMED: <id>[, <id>...].
    def confirmed_ids(pr)
      comments, error = @fetcher.call(pr)
      raise error if error
      comments.flat_map { |body| body.to_s.scan(CONFIRM) }
              .flatten
              .flat_map { |list| list.split(",") }
              .map(&:strip)
              .reject(&:empty?)
    end

    def request(pr, items)
      body = +"This change cannot be closed until a human confirms the following, verified in reality rather than inferred:\n\n"
      items.each { |item| body << "- `#{item['id']}`: #{item['description']}\n" }
      body << "\nReply with `CONFIRMED: <id>[, <id>...]` once each has actually been checked.\n"
      @poster.call(pr, body)
    end

    private

    def real_comments(pr)
      out, status = Open3.capture2e(*%W[gh pr view #{pr} --json comments], chdir: @root)
      return [[], "gh pr view failed: #{out}"] unless status.success?
      [JSON.parse(out).fetch("comments", []).map { |c| c["body"] }, nil]
    rescue StandardError => e
      [[], "#{e.class}: #{e.message}"]
    end

    def real_comment(pr, body)
      Open3.capture2e(*%W[gh pr comment #{pr} --body #{body}], chdir: @root)
    end
  end
end
