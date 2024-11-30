# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    class Deploy < Supervisor::App::Base
      include SSHKit::DSL

      option ['--host'], 'HOST', 'the host to deploy to', required: true
      option ['--skip-docker'], :flag, 'skip Docker installation'
      option ['--skip-traefik'], :flag, 'skip Traefik deployment'

      def execute
        @host = SSHKit::Host.new(host)

        Supervisor::App::Services::Prerequisites.new(host, settings).run
        Supervisor::App::Services::Docker.new(host, settings).run unless skip_docker?
        Supervisor::App::Services::Traefik.new(host, settings).run unless skip_traefik?
        Supervisor::App::Services::Supervisor.new(host, settings).run
      rescue SSHKit::Runner::ExecuteError => e
        bailout(e.message)
      end
    end
  end
end
