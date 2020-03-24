Gem::Specification.new do |s|
  s.name        = 'revs'
  s.version     = '2.0.0.SNAPSHOT'
  s.date        = '2020-03-23'
  s.platform    = 'java'
  s.summary     = "EventSwarm for JRuby"
  s.description = "Ruby lib for writing EventSwarm apps"
  s.authors     = ["Andrew Berry"]
  s.email       = 'andyb@deontik.com'
  s.homepage    = 'https://github.com/eventswarm/revs'
  s.license     = 'Apache-2.0'
  s.files       = ['lib/revs.rb'] + Dir['lib/revs/*.rb'] + Dir['lib/app/views/revs/*.haml'] + Dir['lib/config/templates/*']
  s.require_paths = ['lib']
  s.requirements << 'jar log4j, log4j, 1.2.17'
  s.requirements << 'jar org.json, json, 20190722'
  s.requirements << 'jar org.twitter4j, twitter4j-core, 4.0.7'
  s.requirements << 'jar org.twitter4j, twitter4j-stream, 4.0.7'
  s.requirements << 'jar com.opencsv, opencsv, 5.1'
  s.requirements << 'jar com.fasterxml.uuid, java-uuid-generator, 4.0.1'
  s.requirements << 'jar com.eventswarm, eventswarm, 2.0-SNAPSHOT'
  s.requirements << 'jar com.eventswarm, eventswarm-social, 2.0-SNAPSHOT'
  s.add_dependency('activesupport', '~> 4.1')
  s.add_dependency('uuid', '~>2.3')
  s.add_dependency('clickatell', '~>0.8')
  s.add_dependency('mail', '~>2.7')
  s.add_runtime_dependency('jar-dependencies')
end
