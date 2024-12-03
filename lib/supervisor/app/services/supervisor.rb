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
          ::Supervisor::App::Services::Hook.new(@host, @settings, 'pre-supervisor-deploy').run

          command = command()
          on @host do
            as :root do
              execute :mkdir, '-p', '/var/lib/supervisor'
              execute :chown, '-R', '1001:1001', '/var/lib/supervisor'
              execute :docker, *command
            end
          end

          ::Supervisor::App::Services::Hook.new(@host, @settings, 'post-supervisor-deploy').run
        end

        private

        def command
          command = %w[
            run --detach --restart always
            --name supervisor
            --volume /var/run/docker.sock:/var/run/docker.sock
            --volume /var/lib/supervisor:/rails/storage
          ]
          command += labels
          command += env
          command += ['ghcr.io/tschaefer/supervisor:main']

          command
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
