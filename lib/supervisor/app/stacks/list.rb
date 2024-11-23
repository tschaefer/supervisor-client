# frozen_string_literal: true

require 'tty-table'

require 'active_support'
require 'active_support/core_ext'

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class ListCommand < Supervisor::App::BaseCommand
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
