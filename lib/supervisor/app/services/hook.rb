# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Hook
        include SSHKit::DSL

        def initialize(host, settings, hook)
          @host = host
          @settings = settings
          @hook = hook
        end

        def run
          return unless @settings.deploy&.hooks_path&.presence
          return unless hook_exist?

          execute_hook
        end

        private

        def execute_hook
          file = hook_file
          hook = @hook

          on @host do
            as :root do
              tmpdir = capture :mktemp, '--directory'
              upload! file, "#{tmpdir}/hook"
              succeeded = execute "#{tmpdir}/hook", raise_on_non_zero_exit: false
              execute :rm, '-rf', tmpdir

              unless succeeded
                error "Hook #{hook} failed"
                exit 1
              end
            end
          end
        end

        def hook_exist?
          Pathname.new(hook_file).exist?
        end

        def hook_file
          File.join(@settings.deploy.hooks_path, @hook)
        end
      end
    end
  end
end
