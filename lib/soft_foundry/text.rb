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
