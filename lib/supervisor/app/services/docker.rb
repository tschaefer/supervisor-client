# frozen_string_literal: true

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
                tmdir = capture :mktemp, '--directory'
                # https://github.com/capistrano/sshkit/issues/373
                execute :chmod, '777', tmdir
                within tmdir do
                  execute :curl, '-fsSL', 'https://get.docker.com', '-o', 'get-docker.sh'
                  execute :sh, 'get-docker.sh'
                  execute :rm, 'get-docker.sh'
                end
                execute :rm, '-rf', tmdir
              end
            end
          end
          run_post_hook
        end

        def run_post_hook
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'post-docker-setup').run
        end
      end
    end
  end
end
