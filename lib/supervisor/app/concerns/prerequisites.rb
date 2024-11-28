# frozen_string_literal: true

module Supervisor
  module App
    module Concerns
      module Prerequisites
        extend ActiveSupport::Concern

        included do
          def prerequisites!
            on @host do
              unless test '[ "${EUID:-$(id -u)}" -eq 0 ] || command -v sudo || command -v su'
                error "You need to be root or have sudo installed on #{host}"
                exit 1
              end

              unless test 'command -v curl'
                error "You need to have curl installed on #{host}"
                exit 1
              end
            end
          end
        end
      end
    end
  end
end
