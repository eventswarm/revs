require 'revs/sender'
require 'mail'
require 'erb'
require 'revs/log4_j_logger'
require 'revs/app_config'

# alert sender for HTML email
class EmailSender
  include Sender
  include Log4JLogger

  attr_accessor :text_template, :subject_template, :html_template

  class << self
    def smtp_defaults(host=AppConfig.smtp_host, port=AppConfig.smtp_port, user_name=AppConfig.smtp_user, password=AppConfig.smtp_password)
      Mail.defaults do
        delivery_method :smtp, {
          :address => host,
          :port => port,
          :user_name => user_name,
          :password => password,
        }
      end
    end

    def bcc=(address)
      @bcc = address
    end

    def bcc
      @bcc
    end

    def bcc?
      !@bcc.nil?
    end
  end

  DEFAULT_SUBJECT = "Eventswarm has matched your rule"
  DEFAULT_SUBJECT_TEMPLATE = ERB.new DEFAULT_SUBJECT
  DEFAULT_TEXT = <<EOF
Eventswarm has matched your rule.
For full results see <%= url %>.

Regards,

#{AppConfig.sig_from}
#{AppConfig.sig_email}
EOF
  DEFAULT_TEXT_TEMPLATE = ERB.new DEFAULT_TEXT

  # need 3 templates: text and html templates for the body and a text template for the subject. Subject and text are
  # assumed to be ERB templates. HTML is assumed to be HAML (view template format for this app)
  def initialize(address, default_url, html_template = nil, text_template = nil, subject_template = nil)
    @text_template = text_template || DEFAULT_TEXT_TEMPLATE
    @subject_template = subject_template || DEFAULT_SUBJECT_TEMPLATE
    @html_template = html_template
    @address = address
    @default_url = default_url
  end

  #
  # Send a notification for the specified event. Extra params can include any value required by
  # your template. If a 'url' parameter is specified, it will be used in place of the default
  # url specified when creating this instance
  #
  # Returns true if the notification was sent, or false if rate limiting blocked sending
  #
  def send(trigger, event, other = {})
    logger.info "Sending alert email to #{@address}"
    super(trigger, event, other) do |vars|
      mail = Mail.new(:to => @address, :from => AppConfig.email_from, :subject => @subject_template.result(vars))
      mail.bcc = EmailSender.bcc if EmailSender.bcc?
      mail.text_part = Mail::Part.new(:body => @text_template.result(vars))
      mail.html_part = Mail::Part.new(:content_type => 'text/html; charset=UTF-8', :body => @html_template.render(vars)) unless @html_template.nil?
      mail.deliver
      logger.info "Alert email has been sent to #{@address}."
    end
  end
end
