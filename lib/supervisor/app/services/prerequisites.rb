# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Prerequisites
        include SSHKit::DSL

        def initialize(host, settings)
          @host = host
          @settings = settings
        end

        def run
          tools!
          copy_hooks_dir
        end

        private

        def tools!
          on @host do
            unless test '[ "${EUID:-$(id -u)}" -eq 0 ] || command -v sudo || command -v su'
              error "You need to be root or have sudo installed on #{@host}"
              exit 1
            end

            unless test 'command -v curl'
              error "You need to have curl installed on #{@host}"
              exit 1
            end
          end
        end

        def copy_hooks_dir
          return unless @settings.deploy&.hooks_path&.present?

          hooks = @settings.deploy.hooks_path
          on @host do
            execute :rm, '-rf', '/tmp/supervisor_hooks'
            upload! hooks, '/tmp/supervisor_hooks', recursive: true
          end
        end
      end
    end
  end
end
