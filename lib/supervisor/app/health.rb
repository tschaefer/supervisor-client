# frozen_string_literal: true

require_relative 'base'

module Supervisor
  module App
    class HealthCommand < Supervisor::App::BaseCommand
      option ['--json'], :flag, 'output as JSON'
      option ['--quiet'], :flag, 'show no output'

      def execute
        health = call(:health_check)
        @code = health.code

        if quiet?
          healthy? ? exit(0) : exit(1)
        end

        if healthy?
          puts 'Supervisor service is healthy.'
          exit 0
        end

        bailout('Supervisor service is not healthy.')
      end

      private

      def healthy?
        @code == 200
      end
    end
  end
end
