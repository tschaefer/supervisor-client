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
      end
    end
  end
end
