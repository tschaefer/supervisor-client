# frozen_string_literal: true

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class LogsCommand < BaseCommand
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

          log = call(:stack_last_logs_entry, stack_uuid)
          puts table(log)
        end

        private

        def stream
          configure
          Supervisor.stack_logs(stack_uuid) do |chunk|
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
          rows = log.each_pair.filter_map do |key, value|
            ["#{key.titleize.rjust(9)}:", value]
          end

          TTY::Table
            .new(rows:)
            .render(:basic, multiline: true)
        end
      end
    end
  end
end
