# frozen_string_literal: true

require_relative '../base'
require_relative 'concerns/manifest'

module Supervisor
  module App
    module Stacks
      class UpdateCommand < Supervisor::App::BaseCommand
        include Supervisor::App::Stacks::Concerns::Manifest

        parameter 'STACK_UUID', 'the UUID of the stack to update'

        option ['--manifest-file'], 'FILE', 'manifest file', required: true, attribute_name: :file
        option ['--decrypt'], :flag, 'decrypt manifest values using sops'

        def execute
          manifest = load_manifest_file(file)

          call(:update_stack, stack_uuid, manifest)
        end
      end
    end
  end
end
