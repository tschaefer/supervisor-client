# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Redeploy < Supervisor::App::Base
      include SSHKit::DSL
      include Supervisor::App::PreparesSSHKit

      option ['--host'], 'HOST', 'the host to redeploy to', required: true
      option ['--verbose'], :flag, 'show SSHKit output'
      option ['--with-traefik'], :flag, 'redeploy Traefik'

      def execute
        setup_sshkit
        check_prerequisites
        redeploy_traefik
        redeploy_supervisor

        puts unless verbose?
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end

      private

      def check_prerequisites
        Supervisor::App::Services::Prerequisites.new(host, settings).run
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
        image = settings&.dig(:deploy, :supervisor, :image) || 'ghcr.io/tschaefer/supervisor:main'
        on @host do
          as :root do
            execute :docker, 'pull', image
            execute :docker, 'rm', '--force', 'supervisor'
          end
        end
        Supervisor::App::Services::Supervisor.new(host, settings).run
      end
    end
  end
end
