require 'revs'
require 'revs/log4_j_logger'

java_import 'com.eventswarm.DuplicateEventAction'

class DuplicateAction
  include DuplicateEventAction
  include Log4JLogger

  def initialize(&block)
    logger.debug "Creating new DuplicateAction"
    @handler = block
  end

  def execute(trigger, first, second)
    logger.debug "Attempting to call ruby block with trigger: #{trigger} and events: #{first}, #{second}"
    @handler.call trigger, first, second
  end
end
