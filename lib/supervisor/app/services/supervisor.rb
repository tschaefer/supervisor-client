# frozen_string_literal: true

require 'securerandom'
require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Supervisor
        include SSHKit::DSL

        delegate :argumentize, to: ::Supervisor::App::Services::Utils

        def initialize(host, settings)
          @host = host
          @settings = settings
        end

        def run
          pre_hook
          ensure_network

          command = docker_command
          on @host do
            as :root do
              execute :mkdir, '-p', '/var/lib/supervisor'
              execute :chown, '-R', '1001:1001', '/var/lib/supervisor'
              execute :docker, *command
            end
          end

          post_hook
        end

        private

        def pre_hook
          return if @settings.deploy&.hooks_path&.empty?

          on @host do
            as :root do
              execute '/tmp/supervisor_hooks/pre-supervisor' if test '[ -e /tmp/supervisor_hooks/pre-supervisor ]'
            end
          end
        end

        def post_hook
          return if @settings.deploy&.hooks_path&.empty?

          on @host do
            as :root do
              execute '/tmp/supervisor_hooks/post-supervisor' if test '[ -e /tmp/supervisor_hooks/post-supervisor ]'
            end
          end
        end

        def docker_command
          command = %w[
            run --detach --restart always
            --name supervisor
            --volume /var/run/docker.sock:/var/run/docker.sock
            --volume /var/lib/supervisor:/rails/storage
            --network supervisor
          ]
          command += labels
          command += env
          command += ['ghcr.io/tschaefer/supervisor:main']

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
          rule = "Host(\\\"#{URI.parse(@settings.api.uri).host}\\\")"

          labels = {
            'traefik.enable' => 'true',
            'traefik.http.routers.supervisor.tls' => 'true',
            'traefik.http.routers.supervisor.tls.certresolver' => 'letsencrypt',
            'traefik.http.routers.supervisor.rule' => rule,
            'traefik.http.routers.supervisor.entrypoints' => 'websecure'
          }
          labels.merge!(@settings.deploy&.supervisor&.labels || {})

          argumentize(labels, prefix: '--label ')
        end

        def env
          env = {
            'SECRET_KEY_BASE' => SecureRandom.hex(16),
            'SUPERVISOR_API_KEY' => @settings.api.token
          }
          env.merge!(@settings.deploy&.supervisor&.env || {})

          argumentize(env, prefix: '--env ')
        end
      end
    end
  end
end
