require 'uuid'
require 'set'
require 'active_support/core_ext/object/blank'
require 'eventswarm-jar'
require 'revs/triggers'
require 'revs/email_sender'
require 'revs/sms_sender'
require 'revs/pattern'
require 'revs/log4_j_logger'
require 'erb'
require 'revs/app_config'

java_import 'com.eventswarm.SizeThresholdAction'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.RemoveEventAction'
java_import 'com.eventswarm.expressions.EventOnceOnly'
java_import 'com.eventswarm.abstractions.SizeThresholdMonitor'
java_import 'com.eventswarm.expressions.TrueExpression'
java_import 'com.eventswarm.expressions.EventMatchAction'
java_import 'com.eventswarm.expressions.ComplexExpressionMatchAction'
java_import 'com.eventswarm.eventset.ThreadingPassThru'


class Alerter
  include Log4JLogger

  # TODO: can we be more generic than this
  include SizeThresholdAction
  include EventMatchAction
  include AddEventAction
  include RemoveEventAction
  include ComplexExpressionMatchAction

  # Types of senders
  EMAIL = "email"
  SMS = "SMS"
  SENDER_TYPES = [EMAIL, SMS]

  # Types of alerters
  SINGLE_MATCH = '1'
  THRESHOLD_MATCH = 'n'
  ALERTER_TYPES = [SINGLE_MATCH, THRESHOLD_MATCH]
  ALERTER_STRINGS = {SINGLE_MATCH => 'one match', THRESHOLD_MATCH => 'multiple matches'}

  # default limit on number of alerts before disabling is 1
  ALERT_LIMIT = 1

  class << self; attr_accessor :base_url; attr_reader :alerters end
  @alerters = []
  @base_url = "#{AppConfig.base_url}patterns"

  attr_accessor :json, :parsed_json, :alert_events, :action

  # Alerters are created from json, either posted from a web page or client app, or loaded from disk
  # The alerter action field should be registered against the upstream expression
  # When creating, the base URL of the application /patterns route from the perspective of the end user
  # should be passed if possible
  def initialize(json, base_url = "#{AppConfig.base_url}patterns")
    @json = json
    @parsed_json = JSON.parse(json, :symbolize_names => true)
    @alert_events = {}
    @alert_counter = 0
    @alert_limit = ALERT_LIMIT
    @limit_counter = 0
    check_uuid
    check_base_url base_url
    logger.debug "Parsed alert JSON: #{@parsed_json}"
    @action = setup_monitor self.pattern
    @sender = create_sender base_url
  end

  def setup_monitor(pattern)
    enable
    # create a queue to deliver alerts in a separate thread, avoiding blocking of processing
    @delivery_queue = ThreadingPassThru.new 1
    Triggers.add_remove pattern.results, @delivery_queue
    # register self against the remove trigger of the result set so that we can constrain size of held alert set
    Triggers.remove pattern.results, self
    logger.info "Adding #{self.uuid} as alerter for #{pattern.name}"
    pattern.add_alerter(self)
    if alert_type == THRESHOLD_MATCH
      logger.info "Creating threshold monitor"
      # create a size threshold monitor to trigger when the size of the result set reaches a threshold
      @monitor = SizeThresholdMonitor.new threshold
      @monitor.registerAction self
      logger.info "Registering alert on threshold monitor"
      Triggers.add_remove @delivery_queue, @monitor
      @monitor.registerAction self
    else
      logger.info "Registering alert directly"
      Triggers.add_remove @delivery_queue, self
    end
  end

  def shutdown_monitor(pattern)
    disable
    logger.info "Removing #{self.uuid} as alerter for #{pattern.name}"
    Triggers.un_remove(pattern.results, self)
    pattern.remove_alerter(self)
    logger.info "Unregistering alerter from pattern"
    if @monitor
      Triggers.un_add_remove(pattern.results, @delivery_queue)
    else
      Triggers.un_add_remove(pattern.results, self)
    end
  end


  def enabled?
    @limit_counter < @alert_limit
  end

  def check_uuid
    if @parsed_json[:uuid].nil?
      # add a UUID if we don't already have one
      @parsed_json[:uuid] = UUID.generate(:compact)
      @json = JSON.generate(@parsed_json)
    end
  end

  def check_base_url url
    if @parsed_json[:base_url].nil?
      # set a base URL if we don't already have one
      @parsed_json[:base_url] = url
      @json = JSON.generate(@parsed_json)
    end
  end

  def id
    self.uuid
  end

  def alert_type
    @parsed_json[:alert_type]
  end

  def threshold
    @threshold ||= @parsed_json.has_key?(:threshold) ? Integer(@parsed_json[:threshold]) : 0
  end

  def window
    Integer(@parsed_json[:window])
  end

  def pattern_name
    @parsed_json[:pattern_name]
  end

  def address_type
    @address_type = @parsed_json[:address_type]
  end

  def address
    @parsed_json[:address]
  end

  def uuid
    @parsed_json[:uuid]
  end

  def event(index)
    @alert_events[index]
  end

  def subject_template
    ERB.new @parsed_json[:subject] unless @parsed_json[:subject].blank?
  end

  def message_template
    ERB.new @parsed_json[:message] unless @parsed_json[:message].blank?
  end
  # All alerters should be associated with a pattern managed by the Patterns class
  # We could possibly pass this in, but it would make persistence more difficult: the alerter should
  # really know about its pattern and vice versa
  def pattern
    @pattern ||= Pattern.patterns[pattern_name]
  end

  # send an alert when a trigger that we're listening to fires
  def execute(trigger, event, *args)
    begin
      case
        when Triggers.is_add?(trigger) || Triggers.is_match?(trigger) || Triggers.is_complex_match?(trigger)
          if enabled?
            logger.info "Generating a match alert for #{pattern.name}"
            add_event event
            @sender.send trigger, event, pattern, self, :index => @alert_counter, :size => 1
          else
            #logger.info  "Alerter #{id} for pattern #{pattern_name} is disabled, ignoring match"
          end
        when Triggers.is_threshold?(trigger)
          if enabled?
            logger.info  "Generating a threshold alert for #{pattern.name}"
            add_event event
            @sender.send trigger, event, pattern, self, :index => @alert_counter, :size => args[0]
          else
            logger.info  "Alerter #{id} for pattern #{pattern_name} is disabled, ignoring match"
          end
        when Triggers.is_remove?(trigger)
          logger.info  "Removing an event from alert set for #{pattern.name}"
          remove_event event
        else
          logger.info  "Unknown trigger received from #{pattern.name}"
          nil
      end
    rescue Exception => ex
      logger.error "Failed to send alert", Java::org.jruby.exceptions.RaiseException.new(ex)
    end
  end

  def add_event(event)
    @alert_counter += 1
    @alert_events[@alert_counter] = event
    @limit_counter += 1
    disable if @limit_counter >= @alert_limit
  end

  def remove_event(event)
    # remove the event from the set of alerts
    @alert_events.delete(@alerts.key(event))
  end

  def remove_at_index(index)
    # remove the event at the specified index
    @alert_events.delete(index)
  end

  def create_sender(base_url)
    case address_type
      when EMAIL
        EmailSender.new address, base_url, nil, message_template, subject_template
      when SMS
        SmsSender.new address, base_url, message_template
    end
  end

  def enable
    @limit_counter = 0
  end

  def disable
    @limit_counter = @alert_limit
  end

  # reset the threshold monitor, if we have one
  def reset_monitor
    @monitor.reset if @monitor
  end

  class << self

    #TODO: deal with names being normalised to the same filename
    def make_filename(alert)
      File.join(Persistence.alerters_dir, alert.id)
    end

    # add an alerter to the set
    def add(alerter)
      @alerters << alerter
      alerter
    end

    # save alerter json so that it can be reloaded on restart
    def save(alerter)
      handle = File.open(make_filename(alerter), 'w')
      handle.write(alerter.json)
      alerter
    end

    # remove an alerter from the set and remove the associated saved json
    def delete(alerter)
      Log4JLogger.logger(self.name).info "Deleting alert #{alerter.id} from pattern #{alerter.pattern_name}"
      alerter.shutdown_monitor(alerter.pattern)
      if @alerters.include?(alerter)
        Log4JLogger.logger(self.name).info  "Removing stored alert file for #{alerter.id}"
        File.delete(make_filename(alerter))
        @alerters.delete(alerter)
      end
    end

    def load_all
      Dir.glob("#{Persistence.alerters_dir}/*") do | path |
        #begin
          add Alerter.new(File.read(path)) if File.stat(path).file?
        #rescue Exception => e
        #  puts "Problem loading alert from #{path}: #{e}"
        #end
      end
    end
  end
end