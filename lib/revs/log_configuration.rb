require 'revs'
require 'log4j-jar'
require 'revs/app_config'
require 'revs/log4_j_logger'
require 'singleton'
require 'revs/email_sender'
require 'revs/events'
require 'revs/add_action'
require 'revs/add_set'
require 'revs/remove_set'
require 'revs/triggers'
require 'singleton'

java_import 'org.apache.log4j.BasicConfigurator'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.events.LogEvent'
java_import 'com.eventswarm.eventset.BoundedDiscreteTimeWindow'
java_import 'com.eventswarm.schedules.SystemClockTickTrigger'
java_import 'com.eventswarm.util.logging.Log4JChannel'
java_import 'com.eventswarm.util.logging.MemoryMonitor'
java_import 'com.eventswarm.util.Escalator'
java_import 'com.eventswarm.util.ThresholdMatchAddAction'
java_import 'com.eventswarm.util.ActionRouter'
java_import 'com.eventswarm.powerset.HashPowerset'
java_import 'com.eventswarm.eventset.EveryNFilter'
java_import 'com.eventswarm.eventset.AddEventQueue'
java_import 'java.util.concurrent.Executors'
java_import 'java.util.concurrent.TimeUnit'

#
# Configuration of logging components to monitor logs and generate notifications
#
class LogConfiguration
  include Log4JLogger
  include Singleton

  MAX_EVENTS = 1000
  MEMORY_CHECK_INTERVAL = 30000

  attr_reader :channel, :window, :router, :memory_monitor

  def initialize
    @established = false
  end

  #
  # Create a new log configuration with the specified window size (seconds) and maximum number of log
  # events to hold in memory
  #
  def setup(window, max=MAX_EVENTS)
    unless @established
      # listen for log events with level of warning or higher
      logger.info "Setting up channels to collect log events"
      setup_memory_monitor
      setup_always_report
      @channel = Log4JChannel.new
      @channel.threshold = Java::org.apache.log4j.Level::WARN
      BasicConfigurator.java_send :configure, [Java::org.apache.log4j.Appender.java_class], @channel
      # keep a bounded window of events
      logger.debug "Setting up buffers and routing"
      @window = BoundedDiscreteTimeWindow.new window, max
      Triggers.add @channel, @window
      @router = Router.new @window
      Triggers.add_remove @window, @router.router
      @established = true
    end
  end

  def setup_memory_monitor
    @memory_monitor = MemoryMonitor.new
    @clock_trigger = SystemClockTickTrigger.new(MEMORY_CHECK_INTERVAL)
    Triggers.tick @clock_trigger, @memory_monitor
    @memory_channel = Log4JChannel.new
    @memory_channel.threshold = Java::org.apache.log4j.Level::WARN
    Log4JLogger::MEMORY_MONITOR.add_appender @memory_channel
    @memory_notifier = Notifier.new Log4JLogger::MEMORY_MONITOR.name, 1, 0, false
    Triggers.add @memory_channel, @memory_notifier.queue
  end

  def setup_always_report
    @always_report = Log4JChannel.new
    @always_report.threshold = Java::org.apache.log4j.Level::DEBUG
    Log4JLogger::ALWAYS_REPORT.add_appender @always_report
    @always_notifier = Notifier.new Log4JLogger::ALWAYS_REPORT.name, 1, 0, false
    Triggers.add @always_report, @always_notifier.queue
  end

  def stop
    logger.info 'Stopping log configuration'
    Triggers.un_add @channel, @window
    Triggers.un_add @window, @router
    @router.errors.classes.clear
    @router.warnings.classes.clear
    logger.info 'Stopping notifiers'
    Notifier.stop_notifiers
    logger.info 'Stopping clock trigger'
    @clock_trigger.stop
    logger.info 'Log configuration stopped'
    @established = false
  end

  class Router
    attr_accessor :router, :errors, :warnings

    def initialize(upstream)
      @router = ActionRouter.new LogEvent::GetLevel::INSTANCE
      @errors = Classifier.new('ERROR,FATAL', 1, 5, 20)
      @warnings = Classifier.new('WARNING', 5, 50)
      @router.put LogEvent::Level::warn, @warnings.classes
      @router.put LogEvent::Level::error, @errors.classes
      @router.put LogEvent::Level::fatal, @errors.classes
      Triggers.add_remove upstream, @router
    end
  end

  class Classifier
    include Log4JLogger

    attr_reader :classes

    def initialize(levels, *thresholds)
      logger.info "Adding log message classifier for #{levels} at thresholds [#{thresholds.join ','}]"
      @levels = levels
      @thresholds = thresholds
      @classes = HashPowerset.new LogEvent::GetClassifier::EVENT_KEY
      Triggers.new_set @classes, AddSet.new{|trigger, set, key| add_set set, key}
    end

    #
    # For each new classifier added, create an escalator and listen
    #
    def add_set(set, key)
      logger.info "Adding log message set for #{key} at level(s) [#{@levels}]"
      escalator = Escalator.new(nil)
      @thresholds.each do |threshold|
        escalator.add_threshold_action threshold, Notifier.new(key, threshold).threshold_action
      end
      Triggers.add_remove set, escalator
    end
  end

  class Notifier
    include Log4JLogger
    include Events

    attr_reader :classifier, :threshold, :threshold_action, :queue, :sender

    MAX_SENT = 10
    DEFAULT_LIMIT = 3600
    LOGGER = Log4JLogger.logger('com.ensift.revs.LogConfiguration::Notifier')
    EXECUTOR_SERVICE = Executors.newFixedThreadPool(5)
    SUBJECT_TEMPLATE = ERB.new "<% if other[:count]>1 %><%= other[:count]%> <%= other[:level] %> messages<% else %> <%= other[:level].capitalize %> message<% end %> from <%= AppConfig.app_name %>:<%= other[:classifier] %>"
    TEXT_TEMPLATE = ERB.new <<EOF
Recent <%= AppConfig.app_name %> log messages from class <%= other[:classifier] %> :

<% if other[:activity] %>
  <% event.events.each do |log_event| %>
    <%= timestamp_to_s(log_event) %> <%= log_event.level.to_s.upcase %>: <%= log_event.short_message %>
  <% end %>
<% else %>
    <%= timestamp_to_s(event) %> <%= event.level.to_s.upcase %>: <%= event.short_message %>
<% end %>

For full details, see the <%= AppConfig.app_name %> log at <%= url %>.

Regards,

<%= AppConfig.sig_from %>
<%= AppConfig.sig_email %>
EOF

    def initialize(classifier, threshold, limit=DEFAULT_LIMIT, threshold_action = true)
      logger.info "Adding notifier for #{classifier} at threshold #{threshold}"
      @threshold = threshold
      @classifier = classifier
      @queue = AddEventQueue.new EXECUTOR_SERVICE
      if threshold_action
        @threshold_action = ThresholdMatchAddAction.new MAX_SENT
        Triggers.add @threshold_action, @queue
      end
      @sender = EmailSender.new AppConfig.reporting_email, AppConfig.base_url, nil, TEXT_TEMPLATE, SUBJECT_TEMPLATE
      logger.debug "Setting rate limit period to #{limit}"
      @sender.limit limit
      @send_action = AddAction.new{|trigger, event| send_email trigger, event}
      Triggers.add @queue, @send_action
      self.class.notifiers << self
    end

    def send_email(trigger, event)
      logger.info "Sending log message notification for #{classifier} at level #{level_to_s(event)} and threshold #{threshold}"
      if @sender.send(trigger, event, count: threshold, level: level_to_s(event), classifier: @classifier, activity: activity?(event))
        logger.info 'Notification sent'
      else
        logger.info 'Notification rate limited'
      end
    end

    def stop
      logger.info "Stopping notifier for #{@classifier}"
      @queue.stop
      self.class.notifiers.delete @queue
      logger.info "Stopped notifier for #{@classifier}"
    end

    def level_to_s(event)
      test = activity?(event) ? event.events.last : event
      case test.level
        when LogEvent::Level::warn
          'warning'
        when LogEvent::Level::error, LogEvent::Level::fatal
          'error'
        when LogEvent::Level::info
          'info'
        when LogEvent::Level::debug
          'debug'
        when LogEvent::Level::trace
          'trace'
        else
          '(no level)'
      end
    end

    class << self
      def notifiers
        @notifiers ||= []
      end

      def stop_notifiers
        LOGGER.info "Attempting to stop notifiers"
        @notifiers.each {|notifier| notifier.stop}
        EXECUTOR_SERVICE.shutdown()
        unless EXECUTOR_SERVICE.await_termination(10, TimeUnit::SECONDS)
          LOGGER.warn "Timeout attempting to stop notifiers"
        end
        @notifiers = nil
      end
    end
  end
end