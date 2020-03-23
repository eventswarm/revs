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
  s.require_paths = ['lib', 'lib/jars']
  s.requirements << 'jar org.apache.logging.log4j, log4j-core'
  s.requirements << 'jar org.twitter4j, twitter4j-core'
  s.requirements << 'jar org.twitter4j, twitter4j-stream'
  s.requirements << 'jar com.opencsv, opencsv'
  s.requirements << 'jar com.fasterxml.uuid, java-uuid-generator'
  s.requirements << 'jar com.eventswarm, eventswarm'
  s.requirements << 'jar com.eventswarm, eventswarm-social'
  s.add_dependency('activesupport', '~> 4.1')
  s.add_dependency('uuid', '~>2.3')
  s.add_dependency('clickatell', '~>0.8')
  s.add_dependency('mail', '~>2.7')
end
