# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)


Gem::Specification.new do |s|
  s.name        = 'log4j-jar'
  s.version     = '1.2.14'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://logging.apache.org/log4j/1.2'
  s.summary     = %q{Log4j jar}
  s.description = %q{}

  s.files         = Dir['lib/log4j-jar.rb'] + Dir['lib/jars/log4j-1.2.14.jar']
  s.require_paths = %w(lib)
end
