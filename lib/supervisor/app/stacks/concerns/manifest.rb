# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      module Concerns
        module Manifest
          extend ActiveSupport::Concern

          included do
            private

            def load_manifest_file(file)
              yaml = decrypt_manifest_values(file) if decrypt?

              begin
                yaml.present? ? YAML.load(yaml) : YAML.safe_load_file(file)
              rescue StandardError => e
                bailout(e.message)
              end
            end

            def decrypt_manifest_values(_file)
              begin
                yaml_encrypted = File.read(file)
              rescue StandardError => e
                bailout(e.message)
              end

              cmd = 'sops decrypt --input-type yaml --output-type yaml --output /dev/stdout /dev/stdin'
              stdout, stderr, status = Open3.capture3(*cmd.split, stdin_data: yaml_encrypted)
              bailout(stderr.strip) if !status.success?

              stdout.strip
            end
          end
        end
      end
    end
  end
end
