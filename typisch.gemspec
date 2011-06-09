lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'typisch/version'

spec = Gem::Specification.new do |s|
  s.name   = "typisch"
  s.version = Typisch::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Matthew Willson']
  s.email = ["matthew@playlouder.com"]
  s.summary = "A schema language / type system / validation framework, for semi-structured data and for data in dynamic languages"

  s.add_development_dependency('autotest')
  s.add_development_dependency('minitest', '~> 2.1.0')
  s.add_development_dependency('mocha', '~> 0.9.12')
  s.add_development_dependency('rcov', '~> 0.9.9')

  s.files = Dir.glob("{lib}/**/*") + ['README.md']
end
