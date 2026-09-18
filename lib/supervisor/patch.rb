# frozen_string_literal: true

module HTTParty
  class Parser
    def json
      require 'json'
      if JSON::VERSION.to_i >= 3
        JSON.parse(body, allow_nan: true)
      else
        JSON.parse(body, quirks_mode: true, allow_nan: true)
      end
    end
  end
end
