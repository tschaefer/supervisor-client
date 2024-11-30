# frozen_string_literal: true

require 'clamp'
require 'hashie'
require 'pastel'
require 'tty-screen'
require 'tty-table'
require 'tty-pager'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/parameter_filter'

Clamp.allow_options_after_parameters = true

module Supervisor
  module App
    class Base < Clamp::Command
      option ['-m', '--man'], :flag, 'show man page' do
        manpage = <<~MANPAGE
          Name:
            supervisor - The command line client for the Supervisor GitOps service

          #{help}
          Authors:
            Tobias Schäfer <github@blackox.org>

          Copyright and License:
            This software is copyright (c) by Tobias Schäfer.

            This package is free software; you can redistribute it and/or
            modify it under the terms of the "MIT License".
        MANPAGE
        TTY::Pager.page(manpage)

        exit 0
      end

      option ['-v', '--version'], :flag, 'show version' do
        puts "supervisor #{Supervisor::VERSION} - 👽 All your stacks are belong to us!"

        exit 0
      end

      private

      def bailout(message)
        warn Pastel.new.red.bold(message)
        exit 1
      end

      def call(method, *)
        configure
        result = Supervisor.send(method, *)

        result = filter_secrets(result) if defined?(unfiltered?) && !unfiltered?

        if defined?(json?) && json?
          puts JSON.pretty_generate(result)
          exit 0
        end

        result
      rescue Supervisor::Error => e
        bailout(e.message)
      end

      def settings
        return @settings if defined?(@settings)

        cfgfile = @cfgfile.presence || File.join(Dir.home, '.supervisor')
        settings = File.readable?(cfgfile) ? YAML.load_file(cfgfile) : bailout('No configuration file found')

        @settings = Hashie::Mash.new(settings)
      end

      def configure
        Supervisor.configure do |config|
          config.base_uri = settings.api.uri   || bailout('No base URI configured')
          config.api_key  = settings.api.token || bailout('No API key configured')
        end
      end

      def filter_secrets(hash)
        secrets = /key|token|passw|secret/i
        filters = [->(k, v) { v.replace('[FILTERED]') if secrets.match?(k) && v.present? }]

        ActiveSupport::ParameterFilter.new(filters).filter(hash)
      end
    end
  end
end
