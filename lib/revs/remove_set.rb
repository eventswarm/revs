require 'revs'
require_jar 'log4j', 'log4j'

java_import 'com.eventswarm.powerset.RemoveSetAction'

class RemoveSet
  include RemoveSetAction
  include Log4JLogger

  def initialize(&block)
    @handler = block
  end

  def execute(trigger, set, key)
    logger.debug "Calling RemoveSetAction for key #{key}"
    @handler.call trigger, set, key
  end
end
