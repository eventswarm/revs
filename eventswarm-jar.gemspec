# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'eventswarm-jar'
  s.version     = '1.0'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://eventswarm.com'
  s.summary     = %q{EventSwarm jar}
  s.description = %q{}

  s.files         = Dir['lib/eventswarm-jar.rb'] + Dir['lib/jars/eventswarm-1.0-SNAPSHOT.jar']
  s.require_paths = %w(lib)
  s.add_dependency('log4j-jar', '~>1.2.14')
  s.add_dependency('opencsv-jar', '~>2.3')
  s.add_dependency('java-uuid-generator-jar', '~>3.1.3')
end
