require 'eventswarm-jar'
require 'revs/triggers'
require 'revs/log4_j_logger'
require 'revs/brief_date'

#
# Interface for all alert senders, includes functions for rate limiting
#
# Note that rate limiting is based on event timestamps not clock time, which might
# lead to some misunderstandings but works better for replay. We should consider
# using clock time.
#
module Sender
  include Log4JLogger

  attr_accessor :default_url

  # the default maximum number of alerts to send when there is no rate limiting
  MAX = 1

  # Check rate limiting and update rate limit fields, then yield binding to caller if sending is enabled
  # 'other' parameters are added to the binding.
  # Returns true if the message was sent or false if rate limiting blocked sending
  def send(trigger, event, other = {})
    @count ||= 0
    if enabled?(event)
      other[:url] = default_url if other[:url].nil?
      add_to_binding other
      yield binding
      @count = @count + 1
      @last = event
      true
    else
      logger.info "Sending disabled due to rate limiting"
      false
    end
  end

  # Set the minimum period (seconds) between notifications
  def limit(period)
    @period = period*1000 # convert to milliseconds for simpler comparisons
  end

  def enabled?(event)
    (!@period.nil? && outside_period?(event)) || @count < MAX
  end

  def outside_period?(event)
    @period.nil? || @last.nil? || (event.header.timestamp.time - @last.header.timestamp.time) > @period
  end

  # reset the alert count
  def reset
    @count = 0
  end

  # for rendering, convert event timestamps to strings
  def timestamp_to_s(event)
    BriefDate.format(Time.at event.header.timestamp.time.to_f/1000)
  end

  # add a set of values from a hash to the current binding
  def add_to_binding(vars={})
    @vars = vars
  end

  # return the value of a var
  def method_missing(m, *args, &block)
    if @vars && @vars[m]
      @vars[m]
    else
      super
    end
  end
end
