# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'opencsv-jar'
  s.version     = '2.3'
  s.platform    = 'java'
  s.authors     = ['Andrew Berry']
  s.email       = ['andyb@deontik.com']
  s.homepage    = 'http://opencsv.sourceforge.net'
  s.summary     = %q{OpenCSV jar}
  s.description = %q{}

  s.files         = Dir['lib/opencsv-jar.rb'] + Dir['lib/jars/opencsv-2.3.jar']
  s.require_paths = %w(lib)
end
