# frozen_string_literal: true

require_relative 'lib/supervisor/version'

Gem::Specification.new do |spec|
  spec.name     = 'supervisor'
  spec.version  = Supervisor::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors  = ['Tobias Schäfer']
  spec.email    = ['github@blackox.org']

  spec.summary     = 'A command line client for the Supervisor GitOps service'
  spec.description = <<~DESC
    #{spec.summary}
  DESC
  spec.homepage = 'https://github.com/tschaefer/supervisor-client'
  spec.license  = 'MIT'

  spec.files                 = Dir['lib/**/*']
  spec.bindir                = 'bin'
  spec.executables           = ['supervisor']
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.3'

  spec.post_install_message = 'All your stacks are belong to us!'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri']       = 'https://github.com/tschaefer/supervisor-client'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/tschaefer/supervisor-client/issues'

  spec.add_dependency 'activesupport', '~> 8.0.0'
  spec.add_dependency 'clamp', '~> 1.3.2'
  spec.add_dependency 'hashie', '~> 5.0'
  spec.add_dependency 'httparty', '~> 0.22'
  spec.add_dependency 'pastel', '~> 0.8.0'
  spec.add_dependency 'tty-pager', '~> 0.14.0'
  spec.add_dependency 'tty-screen', '~> 0.8.2'
  spec.add_dependency 'tty-table', '~> 0.12.0'
  spec.add_dependency 'zeitwerk', '~> 2.7.1'
end
