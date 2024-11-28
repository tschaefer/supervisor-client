# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      class Delete < Supervisor::App::Base
        parameter 'STACK_UUID', 'the UUID of the stack to delete'

        def execute
          call(:delete_stack, stack_uuid)
        end
      end
    end
  end
end
