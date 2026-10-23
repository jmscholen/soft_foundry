# frozen_string_literal: true

module SoftFoundry
  class Error < StandardError; end

  # The target repository, environment, or invocation is at fault. Exit 1.
  class TargetError < Error; end

  # Git could not answer a question the caller cannot guess at. Callers that
  # decide freshness treat it as "unknown", never as "nothing changed".
  class GitError < Error; end

  # Soft Foundry itself is at fault: a broken package, an inconsistent
  # control plane, or an internal exception. Exit 4 with upstream guidance.
  class InternalError < Error
    attr_reader :component, :diagnostic

    def initialize(message, component:, diagnostic: [])
      super(message)
      @component = component
      @diagnostic = Array(diagnostic)
    end
  end
end
