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
            supervisor
          ]

          on @host do
            as :root do
              execute :docker, *command unless test :docker, 'network', 'inspect', 'supervisor', '--format', '{{.Name}}'
            end
          end
        end
      end
    end
  end
end
