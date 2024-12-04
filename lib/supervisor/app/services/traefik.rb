# frozen_string_literal: true

require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Traefik
        include SSHKit::DSL
        include ::Supervisor::App::Services::EnsuresNetwork

        delegate :argumentize, to: ::Supervisor::App::Services::Utils

        def initialize(host, settings)
          @host = host
          @settings = settings
        end

        def run
          run_pre_hook
          ensure_network
          run_command
          run_post_hook
        end

        private

        def run_command
          command = build_command
          on @host do
            as :root do
              execute :mkdir, '-p', '/var/lib/traefik/certs.d'
              execute :docker, *command
            end
          end
        end

        def run_pre_hook
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'pre-traefik-deploy').run
        end

        def run_post_hook
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'post-traefik-deploy').run
        end

        def build_command
          command = %w[
            run --detach --restart always
            --name traefik
            --volume /var/run/docker.sock:/var/run/docker.sock
            --volume /var/lib/traefik:/etc/traefik
            --network supervisor
            --publish 80:80 --publish 443:443
          ]
          command += build_env
          command += [set_image]
          command += build_args

          command
        end

        def set_image
          @settings.deploy&.traefik&.image || 'traefik:v3.2.1'
        end

        def build_args
          email = "acme@#{URI.parse(@settings.api.uri).host}"

          args = {
            'providers.docker.exposedbydefault' => 'false',
            'entrypoints.web.address' => ':80',
            'entrypoints.websecure.address' => ':443',
            'certificatesresolvers.letsencrypt.acme.email' => email,
            'certificatesresolvers.letsencrypt.acme.storage' => '/etc/traefik/certs.d/acme.json',
            'certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint' => 'web'
          }
          args.merge!(@settings.deploy&.traefik&.args || {})

          argumentize(args)
        end

        def build_env
          env = {}
          env.merge!(@settings.deploy&.traefik&.env || {})

          argumentize(env, prefix: '--env ')
        end
      end
    end
  end
end
