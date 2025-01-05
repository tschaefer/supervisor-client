# frozen_string_literal: true

module Supervisor
  module App
    class Dashboard < Supervisor::App::Base
      option ['--open'], :flag, 'open in browser'

      def execute
        dashboard = URI.parse(settings.api.uri).tap { |u| u.path = '/dashboard' }
        return system('open', dashboard) if open?

        puts dashboard
      end
    end
  end
end
