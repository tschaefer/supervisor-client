# frozen_string_literal: true

module Supervisor
  module App
    module Services
      module Utils
        class << self
          def argumentize(hash, prefix: '--')
            hash.map { |key, value| "#{prefix}#{key}=\"#{value}\"" }
          end
        end
      end
    end
  end
end
