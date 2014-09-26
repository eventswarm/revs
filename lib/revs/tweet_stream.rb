require 'java'
require 'eventswarm-jar'
require 'eventswarm-social-jar'
require 'json-jar'
require 'twitter4j-jars'
require 'revs/log4_j_logger'
require 'revs/app_config'
require 'revs/triggers'
require 'revs/twitter_connection'

java_import 'com.eventswarm.social.channels.JsonStatusListenerChannel'
java_import 'twitter4j.ConnectionLifeCycleListener'
java_import 'com.eventswarm.eventset.LastNWindow'
java_import 'com.eventswarm.eventset.SyncFilter'
java_import 'com.eventswarm.eventset.ThreadingPassThru'
java_import 'com.eventswarm.eventset.MutablePassThruImpl'
java_import 'twitter4j.conf.ConfigurationBuilder'
java_import 'twitter4j.TwitterStreamFactory'

class TweetStream
  include Log4JLogger
  include ConnectionLifeCycleListener

  # class to manage singleton twitter stream channel

  attr_reader :channel, :sync_filter, :user_ids, :track, :connected, :splitter

  class << self
    def create(executor = nil)
      @instance ||= TweetStream.new executor
    end

    def connect
      if @instance.user_ids.empty? && @instance.track.empty?
        Log4JLogger.logger(self.name).warn "No user_ids or track keywords, so not connecting"
      else
        Log4JLogger.logger(self.name).info "Connecting to twitter"
        @instance.channel.connect
      end
    end

    def connected?
      @instance && @instance.connected?
    end

    def disconnect
      if connected?
        @instance.channel.disconnect
      end
    end

    def add_filters(names, tags_and_words)
      @instance.add_filters names, tags_and_words
    end

    def remove_filters(names, tags_and_words)
      @instance.remove_filters names, tags_and_words
    end

    def register_action(action)
      Triggers.add @instance.splitter, action
    end

    def unregister_action(action)
      Triggers.un_add @instance.splitter, action
    end

    # Register an abstraction
    # TODO: work out how to replay from a buffer when a splitter is in place, probably use twitter search api instead
    def register_abstraction(abs)
      Triggers.add @instance.splitter, abs
      Triggers.remove @instance.splitter, abs
    end

    def unregister_abstraction(abs)
      unregister_action abs
      Triggers.un_add_remove @instance.splitter, abs
    end

    def get_user_ids(names)
      if names.size > 0
        Log4JLogger.logger(self.name).info "Retrieving users: #{unadorned_names(names).inspect}"
        user_ids = TwitterConnection.instance.twitter.lookupUsers(unadorned_names(names).to_java(:string)).collect { |user| user.getId }
        Log4JLogger.logger(self.name).info "Successfully mapped user names to ids"
        user_ids
      else
        []
      end
    end

    def factory
      if @stream_factory.nil?
        conf = ConfigurationBuilder.new
        conf.setOAuthConsumerKey AppConfig.twitter_consumer_key
        conf.setOAuthConsumerSecret AppConfig.twitter_consumer_secret
        conf.setOAuthAccessToken AppConfig.twitter_access_token
        conf.setOAuthAccessTokenSecret AppConfig.twitter_access_token_secret
        @stream_factory = TwitterStreamFactory.new(conf.build)
      end
      @stream_factory
    end

    def unadorned_names(names)
      names.collect{|name| name[0] == '@' ? name[1..-1] : name}
    end

    def sync_filter
      @instance.sync_filter
    end

    def state
      state = {'Connected' => "#{connected?}"}
      if connected?
        state.merge!({'Tweet count' => "#{@instance.channel.count}",
                      'Error count' => "#{@instance.channel.error_count}",
                      'Following' => "#{@instance.user_ids.size} users",
                      'Tracking' => "#{@instance.track.size} tags and keywords"})
      end
      state
    end

    def count
      @instance.count
    end
  end

  def add_filters(names, tags_and_words)
    new_users = names.nil? ? [] : TweetStream.get_user_ids(names) - @user_ids
    new_track = tags_and_words.nil? ? [] : tags_and_words - @track
    @user_ids += new_users
    logger.info "Adding new users to filter: #{new_users.join(', ')}"
    @track += new_track
    logger.info "Adding new tracked words to filter: #{new_track.join(', ')}"
    reset_filters @user_ids, @track unless new_users.empty? && new_track.empty?
  end

  # remove the specified filters from our twitter query and reset the stream
  # use this with care, because the stream is shared by many queries: if in doubt, don't do it
  def remove_filters(names, tags_and_words)
    # assume caller is smart enough to know whether we really need to reconnect and just do it
    @user_ids = @user_ids - (TweetStream.get_user_ids(names) || [])
    @track = @track - (tags_and_words || [])
    reset_filters @user_ids, @track
  end

  def reset_filters(user_ids, track)
    @channel.resetFilter user_ids.to_java(Java::long), track.to_java(:String)
    if @connected
      # reconnect to reset the filters if we are already connected
      @channel.disconnect
      @channel.connect
    end
  end

  def connected?
    @connected
  end


  def onConnect()
    logger.debug("twitter4j says we are connected")
    @connected = true
  end

  def onDisconnect()
    logger.debug("twitter4j says we have disconnected")
    @connected = false
  end

  def onCleanUp()
    logger.debug("twitter4j asked us to clean up")
    # do nothing for now
  end

  def count
    @channel.count
  end

  private

  def initialize(executor = nil)
    @connected = false
    @user_ids = []
    @track = []
    @channel = JsonStatusListenerChannel.new TweetStream.factory, @user_ids.to_java(Java::long), @track.to_java(:String)
    @channel.stream.addConnectionLifeCycleListener(self)
    @sync_filter = SyncFilter.new()
    Triggers.add(@channel, @sync_filter)
    if executor.nil?
      @splitter = MutablePassThruImpl.new
    else
      @splitter = ThreadingPassThru.new executor
    end
    Triggers.add(@sync_filter, @splitter)
  end
end
