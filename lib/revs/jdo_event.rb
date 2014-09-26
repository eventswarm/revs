require 'eventswarm-jar'

#
# Reopen JdoEvent to add some convenience methods for ruby usage
#

JdoEvent = com.eventswarm.events.jdo.JdoEvent

class JdoEvent
  def event_id
    header.event_id
  end

  def id
    event_id
  end

  def uuid
    header.uuid.to_s
  end

  def date
    Time.at(self.header.timestamp.time.to_f/1000)
  end

  def source
    header.source.source_id
  end

  def complex_match?
    self.java_kind_of? com.eventswarm.events.ComplexExpressionMatchEvent
  end

  def activity?
    self.java_kind_of? com.eventswarm.events.Activity
  end

  def tweet?
    self.java_kind_of? com.eventswarm.social.events.TweetEntities
  end

  def log?
    self.java_kind_of? com.eventswarm.events.LogEvent
  end

  def event?
    self.java_kind_of? com.eventswarm.events.Event
  end

  def xml?
    self.java_kind_of? com.eventswarm.events.XmlEvent
  end

  def json?
    self.java_kind_of? com.eventswarm.events.JsonEvent
  end
end
