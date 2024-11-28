# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      class Create < Supervisor::App::Base
        include Supervisor::App::Stacks::Concerns::Manifest

        option ['--manifest-file'], 'FILE', 'manifest file', required: true, attribute_name: :file
        option ['--decrypt'], :flag, 'decrypt manifest values using sops'

        def execute
          manifest = load_manifest_file(file)

          call(:create_stack, manifest)
        end
      end
    end
  end
end
