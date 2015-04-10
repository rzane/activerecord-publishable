# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'streaming/version'

Gem::Specification.new do |spec|
  spec.name          = "streaming"
  spec.version       = Streaming::VERSION
  spec.authors       = ["Ray Zane"]
  spec.email         = ["rzane@bodnargroup.com"]
  spec.summary       = %q{Simple server-side events for ActiveRecord models.}
  spec.description   = %q{Push changes to your models to your client using Redis.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", ">= 1.3.0"
  spec.add_dependency "em-hiredis"
  spec.add_dependency "redis"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha"
end
