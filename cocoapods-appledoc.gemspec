# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_appledoc.rb'

Gem::Specification.new do |spec|
  spec.name = 'cocoapods-appledoc'
  spec.version = Pod::AppleDoc::VERSION
  spec.authors = ['Orta Therox', 'Kyle Fuller']
  spec.summary = 'CocoaPods plugin to build documentation for a pod.'
  spec.homepage = 'https://github.com/CocoaPods/cocoapods-appledoc'
  spec.license = 'MIT'
  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'cocoapods', '~> 0.34'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end

