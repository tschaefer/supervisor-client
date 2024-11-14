# frozen_string_literal: true

require 'httparty'
require 'hashie'

require 'openssl'

module Supervisor
  class Client
    include HTTParty
    headers 'Accept' => 'application/json', 'Content-Type' => 'application/json',
            'User-Agent' => "Supervisor/#{Supervisor::VERSION}"
    debug_output $stdout if %w[true yes 1].include?(ENV['SUPERVISOR_DEBUG'])

    attr_accessor :base_uri, :api_key

    def initialize
      @base_uri = nil
      @api_key = nil
    end

    def create_stack(params)
      request(:post, '/stacks', params)
    end

    def list_stacks
      request(:get, '/stacks')
    end

    def show_stack(stack_uuid)
      request(:get, "/stacks/#{stack_uuid}")
    end

    def stack_stats(stack_uuid)
      request(:get, "/stacks/#{stack_uuid}/stats")
    end

    def update_stack(stack_uuid, params)
      request(:patch, "/stacks/#{stack_uuid}", params)
    end

    def delete_stack(stack_uuid)
      request(:delete, "/stacks/#{stack_uuid}")
      true
    end

    def control_stack(stack_uuid, command)
      request(:post, "/stacks/#{stack_uuid}/control", { command: })
      true
    end

    def stack_last_logs_entry(stack_uuid)
      request(:get, "/stacks/#{stack_uuid}/last_logs_entry")
    end

    def stack_logs(stack_uuid, &)
      path = "/stacks/#{stack_uuid}/logs"
      headers = { Authorization: "Bearer #{@api_key}" }

      begin
        response = self.class.get("#{@base_uri}#{path}", headers:, stream_body: true, &)
      rescue StandardError => e
        raise Supervisor::Error, e.message
      end

      error!(response)
    end

    def health_check
      request(:get, '/up', skip_error: true)
    end

    private

    def request(http_method, path, body = nil, headers = nil, skip_error: false)
      options = {}

      options[:headers] = { Authorization: "Bearer #{@api_key}" }
      options[:headers].merge!(headers) if headers

      options[:body] = body.to_json if body

      begin
        response = self.class.send(http_method, "#{@base_uri}#{path}", options)
      rescue StandardError => e
        raise Supervisor::Error, e.message
      end

      error!(response) if !skip_error
      hashify(response.parsed_response)
    end

    def error!(response)
      return if response.success?

      message = if response.code == 422
                  response['error'].keys.map do |key|
                    "#{key.capitalize} #{response['error'][key].join(', ')}"
                  end.join(', ')
                else
                  response['error'] || 'Something went wrong'
                end
      raise Supervisor::Error, message
    end

    def hashify(data)
      if data.is_a?(Array)
        data.map { |stack| Hashie::Mash.new(stack) }
      else
        Hashie::Mash.new(data)
      end
    end
  end
end
