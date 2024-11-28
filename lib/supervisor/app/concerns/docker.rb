# frozen_string_literal: true

module Supervisor
  module App
    module Concerns
      module Docker
        extend ActiveSupport::Concern

        included do
          def install_docker
            return if skip_docker?

            on @host do
              as :root do
                if execute :docker, '-v', raise_on_non_zero_exit: false
                  info 'Docker is already installed'
                  unless execute :docker, 'version', raise_on_non_zero_exit: false
                    error 'Docker is not running'
                    exit 1
                  end
                else
                  info 'Installing Docker'
                  within '/tmp' do
                    execute :curl, '-fsSL', 'https://get.docker.com', '-o', 'get-docker.sh'
                    execute :sh, 'get-docker.sh'
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
