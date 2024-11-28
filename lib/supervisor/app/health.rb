# frozen_string_literal: true

module Supervisor
  module App
    class Health < Supervisor::App::Base
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
