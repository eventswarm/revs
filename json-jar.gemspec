# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'json-jar'
  s.version     = '20140107'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://json.org'
  s.summary     = %q{org.json jar}
  s.description = %q{}

  s.files         = Dir['lib/json-jar.rb'] + Dir['lib/jars/json20140107.jar']
  s.require_paths = %w(lib)
end
