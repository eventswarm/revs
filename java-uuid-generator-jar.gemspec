# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'java-uuid-generator-jar'
  s.version     = '3.1.3'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://wiki.fasterxml.com/JugHome'
  s.summary     = %q{JUG jar}
  s.description = %q{}

  s.files         = Dir['lib/java-uuid-generator-jar.rb'] + Dir['lib/jars/java-uuid-generator-3.1.3.jar']
  s.require_paths = %w(lib)
end
