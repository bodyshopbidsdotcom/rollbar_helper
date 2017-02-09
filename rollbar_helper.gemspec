# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rollbar_helper'

Gem::Specification.new do |spec|
  spec.name          = "rollbar_helper"
  spec.version       = RollbarHelper::VERSION
  spec.authors       = ["Santiago Herrera"]
  spec.email         = ["santi.4096@gmail.com"]

  spec.summary       = %q{Displays a stacktrace in rollbar}
  spec.homepage      = "https://github.com/santi-h/rollbar_helper"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "rollbar", "~> 2.14"
end
