# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Docker
        include SSHKit::DSL

        def initialize(host, settings)
          @host = host
          @settings = settings
        end

        def run
          on @host do
            as :root do
              if execute :docker, '-v', raise_on_non_zero_exit: false
                unless execute :docker, 'version', raise_on_non_zero_exit: false
                  error 'Docker is not running'
                  exit 1
                end
              else
                within '/tmp' do
                  execute :curl, '-fsSL', 'https://get.docker.com', '-o', 'get-docker.sh'
                  execute :sh, 'get-docker.sh'
                end
              end
            end
          end

          docker_setup
        end

        private

        def docker_setup
          return if @settings.deploy&.hooks_path&.empty?

          on @host do
            as :root do
              execute '/tmp/supervisor_hooks/docker-setup' if test '[ -e /tmp/supervisor_hooks/docker-setup ]'
            end
          end
        end
      end
    end
  end
end
