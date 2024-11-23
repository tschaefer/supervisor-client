# frozen_string_literal: true

require_relative 'app/base'
require_relative 'app/health'
require_relative 'app/stacks/control'
require_relative 'app/stacks/create'
require_relative 'app/stacks/delete'
require_relative 'app/stacks/list'
require_relative 'app/stacks/log'
require_relative 'app/stacks/show'
require_relative 'app/stacks/stats'
require_relative 'app/stacks/update'

module Supervisor
  module App
    class Command < Supervisor::App::BaseCommand
      option ['-c', '--configuration-file'], 'FILE', 'configuration file', attribute_name: :cfgfile

      subcommand 'is-healthy', 'Check the health of the Supervisor service', Supervisor::App::HealthCommand
      subcommand 'list', 'List all stacks', Supervisor::App::Stacks::ListCommand
      subcommand 'show', 'Show a stack', Supervisor::App::Stacks::ShowCommand
      subcommand 'stats', 'Show stats of a stack', Supervisor::App::Stacks::StatsCommand
      subcommand 'create', 'Create a stack', Supervisor::App::Stacks::CreateCommand
      subcommand 'update', 'Update a stack', Supervisor::App::Stacks::UpdateCommand
      subcommand 'delete', 'Delete a stack', Supervisor::App::Stacks::DeleteCommand
      subcommand 'control', 'Control a stack', Supervisor::App::Stacks::ControlCommand
      subcommand 'log', 'Show the log of a stack', Supervisor::App::Stacks::LogCommand
    end
  end
end
