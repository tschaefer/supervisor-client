# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Deploy < Supervisor::App::Base
      include SSHKit::DSL
      include Supervisor::App::PreparesSSHKit

      option ['--host'], 'HOST', 'the host to deploy to', required: true
      option ['--skip-docker'], :flag, 'skip Docker installation'
      option ['--skip-traefik'], :flag, 'skip Traefik deployment'
      option ['--verbose'], :flag, 'show SSHKit output'

      def execute
        setup_sshkit
        check_prerequisites
        setup_docker
        deploy_traefik
        deploy_supervisor

        puts unless verbose?
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end

      private

      def check_prerequisites
        Supervisor::App::Services::Prerequisites.new(host, settings).run
      end

      def setup_docker
        return if skip_docker?

        Supervisor::App::Services::Docker.new(host, settings).run
      end

      def deploy_traefik
        return if skip_traefik?

        Supervisor::App::Services::Traefik.new(host, settings).run
      end

      def deploy_supervisor
        Supervisor::App::Services::Supervisor.new(host, settings).run
      end
    end
  end
end
