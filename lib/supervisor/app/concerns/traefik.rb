# frozen_string_literal: true

require 'erb'

module Supervisor
  module App
    module Concerns
      module Traefik
        extend ActiveSupport::Concern

        included do # rubocop:disable Metrics/BlockLength
          def deploy_traefik
            return if skip_traefik?

            yml = create_traefik_config

            on @host do
              as :root do
                execute :mkdir, '-p', '/var/lib/traefik/certs.d'
                upload! StringIO.new(yml), '/var/lib/traefik/traefik.yml'
                execute :docker, 'network', 'create', '--attachable', '--ipv6', 'supervisor'
                execute :docker, 'run', '--detach', '--restart', 'always',
                        '--name', 'traefik',
                        '--volume', '/var/run/docker.sock:/var/run/docker.sock',
                        '--volume', '/var/lib/traefik:/etc/traefik',
                        '--network', 'supervisor',
                        '--publish', '80:80', '--publish', '443:443',
                        'traefik:v3.2.1'
              end
            end
          end

          def create_traefik_config
            template = <<~YAML
              ---
              api:
                insecure: true

              entrypoints:
                web:
                  address: ':80'
                  http:
                    redirections:
                      entrypoint:
                        to: 'websecure'
                        scheme: 'https'
                        permanent: true
                websecure:
                  address: ':443'

              certificatesresolvers:
                letsencrypt:
                  acme:
                    email: '<%= settings.api.email %>'
                    storage: '/etc/traefik/certs.d/acme.json'
                    httpchallenge:
                      entrypoint: 'web'

              providers:
                docker:
                  exposedbydefault: false

              log:
                level: INFO
            YAML

            ERB.new(template, trim_mode: '-').result(binding)
          end
        end
      end
    end
  end
end
