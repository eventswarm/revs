require 'revs'

java_import 'com.eventswarm.RemoveEventAction'

class RemoveAction
  include RemoveEventAction

  def initialize(&block)
    @handler = block
  end

  def execute(trigger, event)
    @handler.call trigger, event
  end
end