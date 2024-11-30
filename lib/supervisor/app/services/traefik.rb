# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Traefik
        include SSHKit::DSL

        delegate :argumentize, to: ::Supervisor::App::Services::Utils

        def initialize(host, settings)
          @host = host
          @settings = settings
        end

        def run
          ensure_network
          command = docker_command

          on @host do
            as :root do
              execute :mkdir, '-p', '/var/lib/traefik'
              execute :docker, *command
            end
          end
        end

        private

        def docker_command
          command = %w[
            run --detach --restart always
            --name traefik
            --volume /var/run/docker.sock:/var/run/docker.sock
            --volume /var/lib/traefik:/etc/traefik
            --network supervisor
            --publish 80:80 --publish 443:443
          ]
          command += labels
          command += env
          command += ['traefik:v3.2.1']
          command += args

          command
        end

        def ensure_network
          on @host do
            as :root do
              unless test 'docker network list --format {{.Name}} | grep -q supervisor'
                execute :docker, 'network', 'create', '--attachable', '--ipv6', 'supervisor'
              end
            end
          end
        end

        def labels
          labels = {}
          labels.merge!(@settings.deploy&.traefik&.labels.presence || {})

          argumentize(labels, prefix: '--label ')
        end

        def args
          email = "acme@#{URI.parse(@settings.api.uri).host}"

          args = {
            'providers.docker.exposedbydefault' => 'false',
            'entrypoints.web.address' => ':80',
            'entrypoints.websecure.address' => ':443',
            'certificatesresolvers.letsencrypt.acme.email' => email,
            'certificatesresolvers.letsencrypt.acme.storage' => '/etc/traefik/acme.json',
            'certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint' => 'web'
          }
          args.merge!(@settings.deploy&.traefik&.args.presence || {})

          argumentize(args)
        end

        def env
          env = {}
          env.merge!(@settings.deploy&.traefik&.env.presence || {})

          argumentize(env, prefix: '--env ')
        end
      end
    end
  end
end
