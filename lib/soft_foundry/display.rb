# frozen_string_literal: true

module SoftFoundry
  # Makes recorded text safe to echo on a terminal line. A record's free text
  # (notes, blocking items, findings) is not trusted to be plain: an escape
  # sequence would restyle or rewrite the screen, a carriage return would
  # overwrite a line, and a newline would forge another fact line.
  module Display
    # Control, format (zero width, bidi), separator and unassigned-style
    # characters, plus the C1 range.
    UNSAFE = /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/
    LIMIT = 5

    module_function

    def safe(value)
      text = value.to_s.dup.force_encoding(Encoding::UTF_8).scrub("?")
      text.gsub(UNSAFE) { |c| format("<U+%04X>", c.ord) }
    end

    # Escaped items joined on one line, cut to `limit` with a count of the rest.
    def list(items, limit: LIMIT)
      items = Array(items).map { |i| safe(i) }
      shown = items.first(limit)
      shown << "and #{items.size - limit} more" if items.size > limit
      shown.join("; ")
    end
  end
end
