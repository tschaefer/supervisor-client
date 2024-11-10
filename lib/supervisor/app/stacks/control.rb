# frozen_string_literal: true

require_relative '../base'

module Supervisor
  module App
    module Stacks
      class ControlCommand < Supervisor::App::BaseCommand
        parameter 'STACK_UUID', 'the UUID of the stack to control'

        option ['--command'], 'COMMAND', 'the command to execute', required: true

        def execute
          call(:control_stack, stack_uuid, command)
        end
      end
    end
  end
end
