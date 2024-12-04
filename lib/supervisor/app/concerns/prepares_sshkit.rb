# frozen_string_literal: true

require 'sshkit'

module Supervisor
  module App
    module PreparesSSHKit
      def setup_sshkit
        SSHKit.config.tap do |cfg|
          cfg.output_verbosity = Logger::DEBUG if %w[true yes 1].include?(ENV['SUPERVISOR_CLIENT_DEBUG'])
          cfg.use_format verbose? ? :pretty : :dot
        end

        effective_host = %w[localhost 127.0.0.1 ::1].include?(host) ? :local : host
        @host = SSHKit::Host.new(effective_host)
      end
    end
  end
end
