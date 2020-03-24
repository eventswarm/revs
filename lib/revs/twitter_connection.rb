require 'java'
require_jar 'com.eventswarm', 'eventswarm-social'
require_jar 'com.eventswarm', 'eventswarm'
require_jar 'org.twitter4j', 'twitter4j-core'
require_jar 'log4j', 'log4j'
require 'revs/app_config'
require 'revs/triggers'
require 'singleton'

java_import 'com.eventswarm.social.channels.JsonStatusQueryChannel'
java_import 'twitter4j.conf.ConfigurationBuilder'
java_import 'twitter4j.TwitterFactory'

# class to manage singleton twitter connection for queries using the currently configured twitter credentials

class TwitterConnection
  include Singleton
  include Log4JLogger

  attr_reader :factory, :twitter

  def initialize
    conf = ConfigurationBuilder.new
    conf.setOAuthConsumerKey AppConfig.twitter_consumer_key
    conf.setOAuthConsumerSecret AppConfig.twitter_consumer_secret
    conf.setOAuthAccessToken AppConfig.twitter_access_token
    conf.setOAuthAccessTokenSecret AppConfig.twitter_access_token_secret
    @factory = TwitterFactory.new(conf.build)
    @twitter ||= factory.get_instance
  end

  # Run a query and deliver the resulting events to the identified actions, retrieving only tweets since
  # the last tweet retrieved
  def query(query, last, *actions)
    channel = JsonStatusQueryChannel.new @twitter, query
    channel.set_since(last) unless last.nil?
    actions.each{|action| channel.register_action action}
    channel.process
  end
end
