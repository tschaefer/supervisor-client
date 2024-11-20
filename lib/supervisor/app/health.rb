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

        if healthy?
          puts 'healthy' unless quiet?
          exit 0
        else
          puts 'unhealthy' unless quiet?
          exit 1
        end
      end

      private

      def healthy?
        @code == 200
      end
    end
  end
end
