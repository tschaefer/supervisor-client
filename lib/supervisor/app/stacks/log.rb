# frozen_string_literal: true

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class LogCommand < BaseCommand
        parameter 'STACK_UUID', 'the UUID of the stack'
        option ['--follow'], :flag, 'follow the log output'
        option ['--json'], :flag, 'output as JSON'

        def execute
          if follow?
            begin
              return stream
            rescue Supervisor::Error => e
              bailout(e.message)
            end
          end

          log = call(:stack_last_log_entry, stack_uuid)
          puts table(log)
        end

        private

        def stream
          configure
          Supervisor.stack_log(stack_uuid) do |chunk|
            regexp = Regexp.new('data: (?<data>.*)\n', Regexp::MULTILINE)
            match = regexp.match(chunk)

            if match.present?
              log = JSON.parse(match[:data])
              if json?
                puts log.to_json
              else
                puts
                puts table(log)
              end
            end
          end
        end

        def table(log)
          max_width = TTY::Screen.width - 13

          rows = log.each_pair.filter_map do |key, value|
            value = value.split("\n").map do |v|
              v.truncate(max_width)
            end.join("\n")

            ["#{key.titleize.rjust(10)}:", value]
          end

          TTY::Table
            .new(rows:)
            .render(:basic, multiline: true)
        end
      end
    end
  end
end
