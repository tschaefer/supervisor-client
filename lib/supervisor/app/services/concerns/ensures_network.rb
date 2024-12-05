# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      module EnsuresNetwork
        include SSHKit::DSL

        def ensure_network
          command = %w[
            network create
            --attachable --ipv6
            --driver bridge --opt com.docker.network.container_iface_prefix=supervisor
          ]
          command += build_network_options
          command << network_name

          test_command = %w[
            network inspect
            --format {{.Name}}
          ]
          test_command << network_name

          on @host do
            as :root do
              execute :docker, *command unless test :docker, *test_command
            end
          end
        end

        private

        def build_network_options
          default = {}
          default.merge!(@settings.deploy&.network&.options || {})

          argumentize(default)
        end

        def network_name
          @settings.deploy&.network&.name || 'supervisor'
        end
      end
    end
  end
end
