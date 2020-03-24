require 'revs'
require_jar 'log4j', 'log4j'

java_import 'com.eventswarm.powerset.NewSetAction'

class AddSet
  include Log4JLogger
  include NewSetAction

  def initialize(&block)
    @handler = block
  end

  def execute(trigger, set, key)
    logger.debug "Calling NewSetAction for key #{key}"
    @handler.call trigger, set, key
  end
end
