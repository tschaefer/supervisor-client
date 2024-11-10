# frozen_string_literal: true

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class DeleteCommand < Supervisor::App::BaseCommand
        parameter 'STACK_UUID', 'the UUID of the stack to delete'

        def execute
          call(:delete_stack, stack_uuid)
        end
      end
    end
  end
end
