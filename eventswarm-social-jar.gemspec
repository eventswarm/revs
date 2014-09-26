# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'eventswarm-social-jar'
  s.version     = '1.0'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://eventswarm.com'
  s.summary     = %q{EventSwarm jar}
  s.description = %q{}

  s.files         = Dir['lib/eventswarm-social-jar.rb'] + Dir['lib/jars/eventswarm-social-1.0-SNAPSHOT.jar']
  s.require_paths = %w(lib)
  s.add_dependency('log4j-jar', '~>1.2.14')
  s.add_dependency('eventswarm-jar', '~>1.0')
  s.add_dependency('json-jar', '20140107')
  s.add_dependency('twitter4j-jars', '~>4.0.2')
end
