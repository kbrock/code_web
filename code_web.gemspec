# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'code_web/version'

Gem::Specification.new do |spec|
  spec.name          = "code_web"
  spec.version       = CodeWeb::VERSION
  spec.authors       = ["Keenan Brock"]
  spec.email         = ["keenan@thebrocks.net"]
  spec.description   = %q{Display the web of method calls in an app}
  spec.summary       = %q{Display methods}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_parser"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
