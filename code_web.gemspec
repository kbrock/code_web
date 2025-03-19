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
  spec.homepage      = "http://github.com/kbrock/code_web"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.metadata    = {
    "homepage_uri" => "https://github.com/kbrock/code_web",
    "changelog_uri" => "https://github.com/kbrock/code_web/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/kbrock/code_web/",
    "bug_tracker_uri" => "https://github.com/kbrock/code_web/issues",
  }
  spec.add_dependency "ruby_parser"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
