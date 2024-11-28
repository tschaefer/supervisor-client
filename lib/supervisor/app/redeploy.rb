# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Redeploy < Supervisor::App::Base
      include SSHKit::DSL
      include Supervisor::App::Concerns::Prerequisites
      include Supervisor::App::Concerns::Supervisor

      option ['--host'], 'HOST', 'the host to deploy to', required: true

      def execute
        @host = SSHKit::Host.new(host)

        prerequisites!
        on @host do
          as :root do
            execute :docker, 'pull', 'ghcr.io/tschaefer/supervisor:main'
            execute :docker, 'rm', '--force', 'supervisor'
          end
        end
        deploy_supervisor
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end
    end
  end
end
