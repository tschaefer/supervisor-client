# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

FileList['tasks/**/*.rake'].each(&method(:import))

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run tasks 'rubocop' by default."
task default: %i[rubocop]
