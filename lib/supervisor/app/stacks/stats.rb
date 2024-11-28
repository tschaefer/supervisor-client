# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      class Stats < Supervisor::App::Base
        parameter 'STACK_UUID', 'the UUID of the stack to show stats'

        option ['--json'], :flag, 'output as JSON'

        def execute
          stats = call(:stack_stats, stack_uuid)

          rows = stats.reverse_each.map do |key, value|
            value = 0 if value.nil?
            ["#{key.titleize.rjust(9)}:", value]
          end

          puts TTY::Table
            .new(nil, rows)
            .render(:basic)
        end
      end
    end
  end
end
