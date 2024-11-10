# frozen_string_literal: true

RSpec.describe Supervisor do
  before do
    described_class.configure do |config|
      config.base_uri = 'https://supervisor.example.com'
      config.api_key = SecureRandom.uuid
    end
  end

  def stub(method, path, body, status, headers: {})
    api_key = described_class.instance_variable_get(:@client).api_key

    headers.merge!(
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'User-Agent' => "Supervisor/#{described_class::VERSION}",
      'Authorization' => "Bearer #{api_key}"
    )

    stub_request(method, "https://supervisor.example.com#{path}")
      .with(headers:)
      .to_return_json(
        status:,
        body: body.to_json
      )
  end

  describe '#list_stacks' do
    context 'when there are no stacks' do
      it 'returns an empty list' do
        body = []
        stub(:get, '/stacks', [], 200)
        stacks = described_class.list_stacks

        expect(stacks.class).to eq(Array)
        expect(stacks).to eq(body)
      end
    end

    context 'when there are stacks' do
      it 'returns a list of stacks' do
        body = [{ 'uuid' => SecureRandom.uuid, 'name' => 'stack' }]
        stub(:get, '/stacks', body, 200)
        stacks = described_class.list_stacks

        expect(stacks.first.class).to eq(Hashie::Mash)
        expect(stacks).to eq(body)
      end
    end
  end

  describe '#show_stack' do
    let(:stack_uuid) { SecureRandom.uuid }

    context 'when the stack exists' do
      it 'returns the stack' do
        body = { 'uuid' => stack_uuid, 'name' => 'stack' }
        stub(:get, "/stacks/#{stack_uuid}", body, 200)
        stack = described_class.show_stack(stack_uuid)

        expect(stack.class).to eq(Hashie::Mash)
        expect(stack).to eq(body)
      end
    end

    context 'when the stack does not exist' do
      it 'raises an error' do
        body = { 'error' => 'Stack not found' }
        stub(:get, "/stacks/#{stack_uuid}", body, :not_found)

        expect { described_class.show_stack(stack_uuid) }.to raise_error(Supervisor::Error)
          .with_message('Stack not found')
      end
    end
  end

  describe '#stack_stats' do
    let(:stack_uuid) { SecureRandom.uuid }

    context 'when the stack exists' do
      it 'returns the stack stats' do
        body = { 'uuid' => stack_uuid, 'processed' => 100, 'failed' => 0, 'last_run' => Time.now.utc.iso8601(3) }
        stub(:get, "/stacks/#{stack_uuid}/stats", body, 200)
        stats = described_class.stack_stats(stack_uuid)

        expect(stats.class).to eq(Hashie::Mash)
        expect(stats).to eq(body)
      end
    end

    context 'when the stack does not exist' do
      it 'raises an error' do
        body = { 'error' => 'Stack not found' }
        stub(:get, "/stacks/#{stack_uuid}/stats", body, :not_found)

        expect { described_class.stack_stats(stack_uuid) }.to raise_error(Supervisor::Error)
          .with_message('Stack not found')
      end
    end
  end

  describe '#health_check' do
    context 'when the service is healthy' do
      it 'returns the healthy information' do
        body = { 'code' => 200, 'status' => { 'database' => 'ok', 'migrations' => 'ok', 'environment' => 'ok' } }
        stub(:get, '/up', body, 200)
        health_check = described_class.health_check

        expect(health_check.class).to eq(Hashie::Mash)
        expect(health_check).to eq(body)
      end
    end

    context 'when the service is not healthy' do
      it 'returns the unhealthy information' do
        body = {
          'code' => 503,
          'errors' => [
            {
              'name' => 'environment',
              'exception' => 'KeyError',
              'message' => 'key not found: "SUPERVISOR_API_KEY"'
            }
          ]
        }
        stub(:get, '/up', body, :internal_server_error)
        health_check = described_class.health_check

        expect(health_check.class).to eq(Hashie::Mash)
        expect(health_check).to eq(body)
      end
    end
  end

  describe '#create_stack' do
    context 'when the stack is created' do
      it 'returns the created stack' do
        body = { 'name' => 'stack' }
        stub(:post, '/stacks', body, 201)
        stack = described_class.create_stack(body)

        expect(stack.class).to eq(Hashie::Mash)
        expect(stack).to eq(body)
      end
    end

    context 'when the stack is not created' do
      it 'raises an error' do
        body = { 'error' => { 'name' => ['has already been taken'] } }
        stub(:post, '/stacks', body, 422)

        expect { described_class.create_stack({}) }.to raise_error(Supervisor::Error)
          .with_message('Name has already been taken')
      end
    end
  end

  describe '#update_stack' do
    let(:stack_uuid) { SecureRandom.uuid }

    context 'when the stack is updated' do
      it 'returns the updated stack' do
        body = { 'name' => 'stack' }
        stub(:patch, "/stacks/#{stack_uuid}", body, 200)
        stack = described_class.update_stack(stack_uuid, body)

        expect(stack.class).to eq(Hashie::Mash)
        expect(stack).to eq(body)
      end
    end

    context 'when the stack is not found' do
      it 'raises an error' do
        body = { 'error' => 'Stack not found' }
        stub(:patch, "/stacks/#{stack_uuid}", body, :not_found)

        expect { described_class.update_stack(stack_uuid, body) }.to raise_error(Supervisor::Error)
          .with_message('Stack not found')
      end
    end

    context 'when the stack is not updated' do
      it 'returns the reason' do
        body = { 'error' => { 'name' => ['has already been taken'] } }
        stub(:patch, "/stacks/#{stack_uuid}", body, 422)

        expect { described_class.update_stack(stack_uuid, body) }.to raise_error(Supervisor::Error)
          .with_message('Name has already been taken')
      end
    end
  end

  describe '#delete_stack' do
    let(:stack_uuid) { SecureRandom.uuid }

    context 'when the stack is deleted' do
      it 'returns true' do
        stub(:delete, "/stacks/#{stack_uuid}", nil, 204)
        result = described_class.delete_stack(stack_uuid)

        expect(result).to be(true)
      end
    end

    context 'when the stack is not found' do
      it 'raises an error' do
        body = { 'error' => 'Stack not found' }
        stub(:delete, "/stacks/#{stack_uuid}", body, :not_found)

        expect { described_class.delete_stack(stack_uuid) }.to raise_error(Supervisor::Error)
          .with_message('Stack not found')
      end
    end
  end

  describe '#control_stack' do
    let(:stack_uuid) { SecureRandom.uuid }

    context 'when the stack is controlled' do
      it 'returns true' do
        body = { 'command' => 'start' }
        stub(:post, "/stacks/#{stack_uuid}/control", body, 204)
        result = described_class.control_stack(stack_uuid, body)

        expect(result).to be(true)
      end
    end

    context 'when the stack is not found' do
      it 'raises an error' do
        body = { 'error' => 'Stack not found' }
        stub(:post, "/stacks/#{stack_uuid}/control", body, :not_found)

        expect { described_class.control_stack(stack_uuid, {}) }.to raise_error(Supervisor::Error)
          .with_message('Stack not found')
      end
    end

    context 'when the command is invalid' do
      it 'raises an error' do
        body = { 'error' => 'Invalid control command' }
        stub(:post, "/stacks/#{stack_uuid}/control", body, :bad_request)

        expect { described_class.control_stack(stack_uuid, {}) }.to raise_error(Supervisor::Error)
          .with_message('Invalid control command')
      end
    end
  end
end
