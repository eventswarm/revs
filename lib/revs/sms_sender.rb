require 'uri'
require 'clickatell'
require 'revs/sender'
require 'revs/log4_j_logger'
require 'revs/app_config'

class SmsSender
  include Sender
  include Log4JLogger


  DEFAULT_SMS = <<EOF
EventSwarm has matched your rule.
Full results at <%= url %>.
EOF
  DEFAULT_SMS_TEMPLATE = ERB.new DEFAULT_SMS
  MAX_LENGTH = 160

  # need 3 templates: text and html templates for the body and a text template for the subject
  def initialize(phone_number, default_url, sms_template = nil)
    @sms_template = sms_template.nil? ? DEFAULT_SMS_TEMPLATE : sms_template
    @phone_number = phone_number
    @default_url = default_url
    @count = 0
  end

  #
  # Send a notification for the specified event. Extra params can include any value required by
  # your template. If a 'url' parameter is specified, it will be used in place of the default
  # url specified when creating this instance
  #
  # Returns true if the notification was sent, or false if rate limiting blocked sending
  #
  def send(trigger, event, other = {})
    logger.info "Sending an SMS alert to #@phone_number"
    super(trigger, event, other) do |vars|
      api = Clickatell::API.authenticate(AppConfig.sms_user_id, AppConfig.sms_user_name, AppConfig.sms_user_token )
      message = @sms_template.result(vars)
      if message.length > MAX_LENGTH
        logger.warn "SMS message too long (#{message.length}), truncating"
        message = message.slice 0, MAX_LENGTH
      end
      api.send_message @phone_number, message
    end
  end

  class << self
    def ping
      api = Clickatell::API.authenticate(AppConfig.sms_user_id, AppConfig.sms_user_name, AppConfig.sms_user_token)
      api.ping 'EventSwarm ping'
    end
  end
end
