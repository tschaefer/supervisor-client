# frozen_string_literal: true

module Supervisor
  module App
    module Stacks
      class Control < Supervisor::App::Base
        parameter 'STACK_UUID', 'the UUID of the stack to control'

        option ['--command'], 'COMMAND', 'the command to execute', required: true

        def execute
          call(:control_stack, stack_uuid, command)
        end
      end
    end
  end
end
