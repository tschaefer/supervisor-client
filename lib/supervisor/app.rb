# frozen_string_literal: true

module Supervisor
  module App
    class Command < Supervisor::App::Base
      option ['-c', '--configuration-file'], 'FILE', 'configuration file', attribute_name: :cfgfile

      subcommand 'is-healthy', 'Check the health of the Supervisor service', Supervisor::App::Health
      subcommand 'list', 'List all stacks', Supervisor::App::Stacks::List
      subcommand 'show', 'Show a stack', Supervisor::App::Stacks::Show
      subcommand 'stats', 'Show stats of a stack', Supervisor::App::Stacks::Stats
      subcommand 'create', 'Create a stack', Supervisor::App::Stacks::Create
      subcommand 'update', 'Update a stack', Supervisor::App::Stacks::Update
      subcommand 'delete', 'Delete a stack', Supervisor::App::Stacks::Delete
      subcommand 'control', 'Control a stack', Supervisor::App::Stacks::Control
      subcommand 'log', 'Show the log of a stack', Supervisor::App::Stacks::Log
    end
  end
end
