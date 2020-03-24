require_jar 'com.eventswarm', 'eventswarm'
require_jar 'com.eventswarm', 'eventswarm-social'
require_jar 'org.twitter4j', 'twitter4j-core'
require 'revs/tweet_stream'
require_jar 'log4j', 'log4j'

java_import 'twitter4j.TwitterFactory'
java_import 'twitter4j.User'
java_import 'com.eventswarm.social.events.TweetEvent'
java_import 'com.eventswarm.social.expressions.HashtagMatcher'
java_import 'com.eventswarm.social.expressions.AuthorMatcher'
java_import 'com.eventswarm.social.expressions.MentionsMatcher'
java_import 'com.eventswarm.social.expressions.RetweetMatcher'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'
java_import 'com.eventswarm.expressions.KeywordMatcher'
java_import 'com.eventswarm.expressions.ANDMatcher'
java_import 'com.eventswarm.expressions.ORMatcher'
java_import 'com.eventswarm.expressions.NOTMatcher'
java_import 'com.eventswarm.expressions.AtLeastNMatcher'
java_import 'com.eventswarm.expressions.EventMatcherExpression'
java_import 'com.eventswarm.powerset.MultiHashPowerset'
java_import 'com.eventswarm.powerset.HashPowerset'
java_import 'com.eventswarm.eventset.LastNWindow'
java_import 'com.eventswarm.eventset.EventMatchPassThruFilter'
java_import 'java.util.ArrayList'

class TweetPattern
  include Log4JLogger

  MATCH_LIMIT = 100

  attr_reader :matcher, :expression, :type, :search_string, :names,  :hashtags, :words

  # Create a new TweetPattern expression from a pattern component provided as parsed JSON (hash)
  def initialize(component)
    @type = Pattern::TWEET
    @parsed_json = component
    @search_string = component[:searchString]
    @include_retweets = component[:retweets]
    split_search_string
    @matcher = create_matcher
  end

  def include_retweets?
    @include_retweets
  end

  def to_s
    "Tweets matching: '#{@search_string}'" + (include_retweets? ? ", including retweets" : "")
  end

  def filter
    @filter ||= EventMatchPassThruFilter.new(@matcher)
  end

  def create_expression(tail=false)
    # TODO: think about whether we need to create a matcher per-expression as well as one for filtering
    if @include_retweets
      @matcher = create_matcher
    else
      # combine matcher with expression to exclude retweets
      matchers = ArrayList.new
      matchers.add create_matcher
      matchers.add NOTMatcher.new(RetweetMatcher.new)
      @matcher = ANDMatcher.new matchers
    end
    EventMatcherExpression.new @matcher, MATCH_LIMIT
  end

  private

  def split_search_string
    @names, @hashtags, @words = [], [], []
    @search_string.split(/[^\w\#\@]+/).each do |token|
      char = token[0,1]
      logger.debug "leading char is #{char}"
      case char
        when '@'
          @names << token
        when '#'
          @hashtags << token
        else
          @words << token.downcase
      end
    end
    logger.debug "Have names #{@names.inspect}"
    logger.debug "Have tags #{@hashtags.inspect}"
    logger.debug "Have words #{@words.inspect}"
  end

  def create_matcher
    matchers = @words.inject(ArrayList.new) {|list, word| list.add KeywordMatcher.new(word); list}
    matchers = @hashtags.inject(matchers) {|list, tag| list.add HashtagMatcher.new(tag); list}
    matchers = TweetStream.unadorned_names(@names).inject(matchers) {|list, name| list.add AuthorMatcher.new(name); list}
    matchers = TweetStream.unadorned_names(@names).inject(matchers) {|list, name| list.add MentionsMatcher.new(name); list}
    if (matchers.size < 2 || (@words.size == 1 && @hashtags.size == 1))
      logger.info 'Exact match filter'
      ANDMatcher.new matchers
    elsif matchers.size == 2
      logger.info 'Matching at least one keyword/hashtag/user'
      ORMatcher.new matchers
    elsif matchers.size > 6
      logger.info 'Matching at least three keywords/hashtags/users'
      AtLeastNMatcher.new matchers, 3
    else
      logger.info 'Matching at least two keywords/hashtags/users'
      AtLeastNMatcher.new matchers, 2
    end
  end
end
