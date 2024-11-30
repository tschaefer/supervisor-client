# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Redeploy < Supervisor::App::Base
      include SSHKit::DSL

      option ['--host'], 'HOST', 'the host to redeploy to', required: true
      option ['--with-traefik'], :flag, 'redeploy Traefik'

      def execute
        @host = SSHKit::Host.new(host)

        Supervisor::App::Services::Prerequisites.new(host, settings).run
        redeploy_traefik
        redeploy_supervisor
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end

      def redeploy_traefik
        return unless with_traefik?

        on @host do
          as :root do
            execute :docker, 'rm', '--force', 'traefik'
          end
        end
        Supervisor::App::Services::Traefik.new(host, settings).run
      end

      def redeploy_supervisor
        on @host do
          as :root do
            execute :docker, 'pull', 'ghcr.io/tschaefer/supervisor:main'
            execute :docker, 'rm', '--force', 'supervisor'
          end
        end
        Supervisor::App::Services::Supervisor.new(host, settings).run
      end
    end
  end
end
