require 'active_support/core_ext/object/blank'
require 'eventswarm-jar'
require 'eventswarm-social-jar'
require 'twitter4j-jars'
require 'revs/events'
require 'revs/log4_j_logger'
require 'resolv'
require 'revs/app_config'

java_import 'com.eventswarm.social.channels.StatusListenerChannel'
java_import 'com.eventswarm.social.events.TweetEvent'
java_import 'com.eventswarm.social.expressions.HashtagMatcher'
java_import 'com.eventswarm.social.expressions.AuthorMatcher'
java_import 'com.eventswarm.eventset.EventSet'
java_import 'com.eventswarm.expressions.KeywordMatcher'
java_import 'com.eventswarm.expressions.ANDMatcher'
java_import 'com.eventswarm.expressions.AtLeastNMatcher'
java_import 'com.eventswarm.expressions.ExpressionAbstraction'

#
# Sinatra helper functions for the EventSwarm lib
#
helpers do
  include Events

  COMPONENTS_PATH = File.join(File.dirname(__FILE__), '..', 'app', 'views', 'revs')

  def include_component(component, scope, locals = {})
    Haml::Engine.new(File.read(component_path(component))).render(scope, locals)
  end

  def component_path(component)
    File.join(COMPONENTS_PATH, component)
  end

  def java_logger
    Log4JLogger.logger("com.eventswarm.revs.#{request.path_info}")
  end

  def log_level_text(level)
    case level
      when LogEvent::Level::error
        'ERROR'
      when LogEvent::Level::fatal
        'FATAL'
      when LogEvent::Level::warn
        'WARNING'
      when LogEvent::level::info
        'INFORMATION'
      when LogEvent::level::debug
        'DEBUG'
      when LogEvent::Level::trace
        'TRACE'
    end
  end

  def request_from(ip)
    name = Resolv.getname(request.ip)
    "#{name} (#{ip})"
  rescue
    "#{ip}"
  end
end
