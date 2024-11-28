# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      class List < Supervisor::App::Base
        option ['--json'], :flag, 'output as JSON'

        def execute
          stacks = call(:list_stacks)
          if stacks.empty?
            puts 'No stacks found.'
            exit 0
          end

          header = %w[Uuid Name]
          rows = stacks.map { |stack| [stack.uuid, stack.name] }

          puts TTY::Table
            .new(header:, rows:)
            .render(:basic)
        end
      end
    end
  end
end
