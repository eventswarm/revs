Gem::Specification.new do |s|
  s.name        = 'revs'
  s.version     = '1.0.0.SNAPSHOT'
  s.date        = '2014-09-25'
  s.summary     = "EventSwarm for JRuby"
  s.description = "Ruby lib for writing EventSwarm apps"
  s.authors     = ["Andrew Berry"]
  s.email       = 'andyb@deontik.com'
  s.files       = ['lib/revs.rb'] + Dir['lib/revs/*.rb'] + Dir['lib/app/views/revs/*.haml'] + Dir['lib/config/*']
  s.require_paths = ['lib', 'lib/jars']
  s.add_dependency('activesupport')
  s.add_dependency('uuid', '~>2.3.7')
  s.add_dependency('twitter-text', '~>1.6.1')
  s.add_dependency('clickatell', '~>0.8.2')
  s.add_dependency('mail', '~>2.5.4')
  s.add_dependency('log4j-jar', '~>1.2.14')
  s.add_dependency('eventswarm-jar', '~>1.0')
  s.add_dependency('eventswarm-social-jar', '~>1.0')
  s.add_dependency('json-jar', '20140107')
  s.add_dependency('twitter4j-jars', '~>4.0.2')
end
