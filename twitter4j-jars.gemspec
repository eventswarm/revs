# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'twitter4j-jars'
  s.version     = '4.0.2'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://twitter4j.org'
  s.summary     = %q{Twitter4j core and streaming jars}
  s.description = %q{}

  s.files         = Dir['lib/eventswarm-jar.rb'] + Dir['lib/jars/twitter4j-core-4.0.2.jar', 'lib/jars/twitter4j-stream-4.0.2.jar']
  s.require_paths = %w(lib)
end
