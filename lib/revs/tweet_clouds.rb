require 'active_support/core_ext/object/blank'
require 'uri'
require 'eventswarm-jar'
require 'eventswarm-social-jar'
require 'twitter4j-jars'
require 'twitter-text'
require 'revs/tweet_stream'
require 'revs/triggers'

java_import 'twitter4j.TwitterFactory'
java_import 'twitter4j.User'
java_import 'com.eventswarm.social.events.TweetEvent'
java_import 'com.eventswarm.social.AuthorEventKey'
java_import 'com.eventswarm.social.MentionsEventKeys'
java_import 'com.eventswarm.social.TagEventKeys'
java_import 'com.eventswarm.social.TweetSetFactory'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'
java_import 'com.eventswarm.eventset.LastNWindow'
java_import 'com.eventswarm.eventset.DiscreteTimeWindow'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.RemoveEventAction'
java_import 'com.eventswarm.util.IntervalUnit'
java_import 'com.eventswarm.expressions.KeywordMatcher'
java_import 'com.eventswarm.expressions.ANDMatcher'
java_import 'com.eventswarm.expressions.ORMatcher'
java_import 'com.eventswarm.expressions.NOTMatcher'
java_import 'com.eventswarm.expressions.AtLeastNMatcher'
java_import 'com.eventswarm.powerset.MultiHashPowerset'
java_import 'com.eventswarm.powerset.HashPowerset'
java_import 'com.eventswarm.abstractions.SizeThresholdMonitor'
java_import 'java.util.ArrayList'

# Class that receives add/remove event triggers and builds author, tag and mention powersets for any
# tweet events added, removing events as required
class TweetClouds
  attr_reader :authors, :tags, :mentions

  SET_FACTORY = TweetSetFactory.new
  AUTHOR_EXTRACTOR = AuthorEventKey.new
  TAG_EXTRACTOR = TagEventKeys.new
  MENTION_EXTRACTOR = MentionsEventKeys.new

  def initialize(event_set)
    @authors = HashPowerset.new SET_FACTORY, AUTHOR_EXTRACTOR
    @tags = MultiHashPowerset.new SET_FACTORY, TAG_EXTRACTOR
    @mentions = MultiHashPowerset.new SET_FACTORY, MENTION_EXTRACTOR
    Triggers.add_remove(event_set, @authors)
    Triggers.add_remove(event_set, @tags)
    Triggers.add_remove(event_set, @mentions)
  end
end
