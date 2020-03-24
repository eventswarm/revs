#
# Helper module to use log4j for logging in Ruby, thus we can manage our logging through one
# infrastructure.
#
require_jar 'log4j', 'log4j'

module Log4JLogger

  ALWAYS_REPORT = Java::org::apache::log4j::Logger.getLogger 'com.eventswarm.always'
  MEMORY_MONITOR = Java::org::apache::log4j::Logger.getLogger 'com.eventswarm.util.logging.MemoryMonitor'

  class << self
    def logger(name)
      Java::org::apache::log4j::Logger.getLogger(name.to_java(:String))
    end
  end

  def logger(name = self.class.name)
    Log4JLogger.logger("com.eventswarm.revs.#{name}")
  end
end
