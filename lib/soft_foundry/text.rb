# frozen_string_literal: true

module SoftFoundry
  # Control-plane files are UTF-8 and may contain characters a Latin-1
  # or US-ASCII default external encoding cannot represent (zero-width
  # scan canaries, learned-rule punctuation). Every text read goes
  # through here so LANG=C does not raise Encoding::CompatibilityError
  # or ArgumentError mid-gate.
  module Text
    module_function

    def read(path)
      File.read(path, mode: "r:UTF-8", invalid: :replace, undef: :replace)
    end
  end
end
