# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect 'prepares_sshkit' => 'PreparesSSHKit'
Dir.glob(File.join(__dir__, '/**/*/')).each do |dir|
  next unless dir.ends_with?('/concerns/')

  loader.collapse(dir)
end
loader.setup

module Supervisor
  class Error < StandardError; end

  class << self
    def configure
      @client = Supervisor::Client.new
      yield @client

      true
    end

    def configured?
      defined?(@client)
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
