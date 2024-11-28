# frozen_string_literal: true

module Supervisor
  module App
    module Concerns
      module Supervisor
        extend ActiveSupport::Concern

        included do # rubocop:disable Metrics/BlockLength
          def deploy_supervisor
            key = SecureRandom.hex(16)
            token = settings.api.token

            template = <<~ENV
              SECRET_KEY_BASE=#{key}
              SUPERVISOR_API_KEY=#{token}
            ENV

            rule = "Host(\\\"#{URI.parse(settings.api.uri).host}\\\")"

            on host do
              as :root do
                execute :mkdir, '-p', '/var/lib/supervisor'
                upload! StringIO.new(template), '/var/lib/supervisor/.env'
                execute :chown, '-R', '1001:1001', '/var/lib/supervisor'
                execute :docker, 'run', '--detach', '--restart', 'always',
                        '--name', 'supervisor',
                        '--volume', '/var/run/docker.sock:/var/run/docker.sock',
                        '--volume', '/var/lib/supervisor:/rails/storage',
                        '--network', 'supervisor',
                        '--env-file', '/var/lib/supervisor/.env',
                        '--label', 'traefik.enable="true"',
                        '--label', 'traefik.http.routers.supervisor.tls="true"',
                        '--label', 'traefik.http.routers.supervisor.tls.certresolver="letsencrypt"',
                        '--label', "traefik.http.routers.supervisor.rule=\"#{rule}\"",
                        'ghcr.io/tschaefer/supervisor:main'
              end
            end
          end
        end
      end
    end
  end
end
