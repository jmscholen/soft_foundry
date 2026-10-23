# frozen_string_literal: true

module SoftFoundry
  # Every file the tool reads for its text (records, templates, assets,
  # hook scripts) is UTF-8 by contract, whatever the process locale says
  # Encoding.default_external is. Invalid bytes are replaced rather than
  # raised on, so a stray byte in a record fails a check instead of
  # crashing the command that would have reported it.
  def self.read_text(path)
    File.binread(path).force_encoding(Encoding::UTF_8).scrub
  end
end

module SoftFoundry
  # Validation for text a person types that is then written into a record.
  # The record is always written through the YAML emitter, never by string
  # building; these checks keep the text itself safe to print back.
  module Text
    ID = /\A[A-Z0-9][A-Z0-9-]*\z/
    ENV_NAME = /\A[A-Z_][A-Z0-9_]*\z/
    RESERVED_ENV_PREFIX = "SOFT_FOUNDRY_"

    module_function

    # Non-empty after strip, at most `max` characters, no control
    # characters (newline, tab, ESC, and NUL included). Returns the stripped text.
    def free_text!(value, label, max: 500)
      text = value.to_s.strip
      raise ArgumentError, "#{label} is required: it may not be empty" if text.empty?
      raise ArgumentError, "#{label} is #{text.length} characters; the limit is #{max}" if text.length > max
      raise ArgumentError, "#{label} may not contain control characters (newline, tab, escape, NUL); put it on one plain line" if text.match?(/\p{Cntrl}/)
      text
    end

    def id!(value, label = "id")
      text = value.to_s
      raise ArgumentError, "#{label} #{text.inspect} must match [A-Z0-9][A-Z0-9-]* (capital letters, digits, and hyphens)" unless text.match?(ID)
      text
    end

    def env_name!(value)
      text = value.to_s
      raise ArgumentError, "environment variable name #{text.inspect} must match [A-Z_][A-Z0-9_]*" unless text.match?(ENV_NAME)
      raise ArgumentError, "environment variable name #{text} begins #{RESERVED_ENV_PREFIX}, which is reserved for soft-foundry" if text.start_with?(RESERVED_ENV_PREFIX)
      text
    end
  end
end
