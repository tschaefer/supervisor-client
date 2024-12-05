# frozen_string_literal: true

require 'securerandom'
require 'sshkit'
require 'sshkit/dsl'

module Supervisor
  module App
    module Services
      class Supervisor
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
              execute :mkdir, '-p', '/var/lib/supervisor'
              execute :chown, '-R', '1001:1001', '/var/lib/supervisor'
              execute :docker, *command
            end
          end
        end

        def run_pre_hook
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'pre-supervisor-deploy').run
        end

        def run_post_hook
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'post-supervisor-deploy').run
        end

        def build_command
          command = %w[
            run --detach --restart always
            --name supervisor
            --volume /var/run/docker.sock:/var/run/docker.sock
            --volume /var/lib/supervisor:/rails/storage
          ]
          command += ['--network', network_name]
          command += build_labels
          command += build_env
          command += [set_image]

          command
        end

        def set_image
          @settings.deploy&.supervisor&.image || 'ghcr.io/tschaefer/supervisor:main'
        end

        def build_labels
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

        def build_env
          env = {
            'SECRET_KEY_BASE' => SecureRandom.hex(48),
            'SUPERVISOR_API_KEY' => @settings.api.token
          }
          env.merge!(@settings.deploy&.supervisor&.env || {})

          argumentize(env, prefix: '--env ')
        end
      end
    end
  end
end
