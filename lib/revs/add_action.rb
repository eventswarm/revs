require 'revs'
require 'revs/log4_j_logger'

java_import 'com.eventswarm.AddEventAction'

class AddAction
  include AddEventAction
  include Log4JLogger

  def initialize(&block)
    logger.debug "Creating new AddAction"
    @handler = block
  end

  def execute(trigger, event)
    logger.debug "Attempting to call ruby block with trigger: #{trigger} and event: #{event}"
    @handler.call trigger, event
  end
end
