# frozen_string_literal: true

require 'securerandom'
require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Deploy < Supervisor::App::Base
      include SSHKit::DSL
      include Supervisor::App::Concerns::Traefik
      include Supervisor::App::Concerns::Prerequisites
      include Supervisor::App::Concerns::Docker
      include Supervisor::App::Concerns::Supervisor

      option ['--host'], 'HOST', 'the host to deploy to', required: true
      option ['--skip-docker'], :flag, 'skip Docker installation'
      option ['--skip-traefik'], :flag, 'skip Traefik deployment'

      def execute
        @host = SSHKit::Host.new(host)

        prerequisites!
        install_docker
        deploy_traefik
        deploy_supervisor
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end
    end
  end
end
