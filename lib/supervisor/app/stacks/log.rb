# frozen_string_literal: true

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class LogCommand < BaseCommand
        parameter 'STACK_UUID', 'the UUID of the stack'
        option ['--entries'], 'ENTRIES', 'number of log entries to show', default: 10
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

          log = call(:fetch_stack_log, stack_uuid, entries)
          format(log)
        end

        private

        def stream
          configure
          Supervisor.follow_stack_log(stack_uuid) do |chunk|
            regexp = Regexp.new('data: (?<data>.*)\n', Regexp::MULTILINE)
            match = regexp.match(chunk)

            if match.present?
              log = JSON.parse(match[:data])
              if json?
                puts log.to_json
              else
                format([log])
              end
            end
          end
        end

        def format(log)
          max_width = TTY::Screen.width - 13

          log.each do |entry|
            puts
            entry.each_pair do |key, value|
              value = value.split("\n").map do |v|
                v.truncate(max_width)
              end.join("\n")

              puts "#{key.titleize.rjust(10)}: #{value}"
            end
          end
        end
      end
    end
  end
end
