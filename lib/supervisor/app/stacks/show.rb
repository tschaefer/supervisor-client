# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'tty-screen'
require 'tty-table'

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class ShowCommand < Supervisor::App::BaseCommand
        parameter 'STACK_UUID', 'the UUID of the stack to show'

        option ['--json'], :flag, 'output as JSON'
        option ['--unfiltered'], :flag, 'output sensitive data'

        def execute
          stack = call(:show_stack, stack_uuid)

          rows = stack.each_pair.filter_map do |key, value|
            next if %w[id updated_at].include?(key)

            value = stringify(value)
            value = truncate(value)
            ["#{key.titleize.rjust(17)}:", value]
          end

          puts TTY::Table
            .new(rows:)
            .render(:basic, multiline: true)
        end

        private

        def stringify(value)
          case value.class.name
          when 'Hashie::Array'
            value.join("\n")
          when 'Hashie::Mash'
            value.map { |k, v| "#{k}=#{v}" }.join("\n")
          else
            value.to_s
          end
        end

        def truncate(value)
          max_width = TTY::Screen.width - 20

          value.split("\n").map do |v|
            v.length > max_width ? v.truncate(max_width) : v
          end.join("\n")
        end
      end
    end
  end
end
