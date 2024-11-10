# frozen_string_literal: true

require_relative 'supervisor/version'
require_relative 'supervisor/client'

module Supervisor
  class Error < StandardError; end

  class << self
    def configure
      @client = Supervisor::Client.new
      yield @client

      true
    end

    def configured?
      @client ? true : false
    end

    def configured!
      raise Error, 'SupervisorClient is not configured' if !configured?
    end

    def method_missing(method, ...)
      configured!
      if @client.respond_to?(method)
        @client.send(method, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      configured!
      @client.respond_to?(method) || super
    end
  end

  private_class_method %i[
    method_missing
    respond_to_missing?
  ]
end
