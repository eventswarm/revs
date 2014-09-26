require 'eventswarm-jar'
require 'eventswarm-social-jar'

# helper methods to work with EventSwarm events
module Events
  def complex_match?(event)
    event.java_kind_of? com.eventswarm.events.ComplexExpressionMatchEvent
  end

  def activity?(event)
    event.java_kind_of? com.eventswarm.events.Activity
  end

  def tweet?(event)
    event.java_kind_of? com.eventswarm.social.events.TweetEntities
  end

  def log?(event)
    event.java_kind_of? com.eventswarm.events.LogEvent
  end

  def event?(event)
    event.java_kind_of? com.eventswarm.events.Event
  end

  def xml?(event)
    event.java_kind_of? com.eventswarm.events.XmlEvent
  end

  def json?(event)
    event.java_kind_of? com.eventswarm.events.JsonEvent
  end
end
