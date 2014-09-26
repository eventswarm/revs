require 'spec_helper'
require 'revs/app_config'
AppConfig.init File.join(File.dirname(__FILE__), '..', 'fixtures', 'config.yml')
require 'revs/sms_sender'
require 'revs/email_sender'

describe "SmsSender" do

  let(:alerter) {double('alerter', :window => 5)}
  let(:pattern) {double('pattern', :name => 'News')}

  it "should generate correct text from default template" do
    url = 'http://waialua.whyanbeel.net:9595/patterns/News'
    size = 10
    text = SmsSender::DEFAULT_SMS_TEMPLATE.result(binding)
    text.should == <<EOF
EventSwarm has matched your rule.
Full results at http://waialua.whyanbeel.net:9595/patterns/News.
EOF
  end

  it "should ping the API in secure mode" do
    SmsSender.ping
  end

  it "should send a real SMS" do
    sender = SmsSender.new(AppConfig.sms_test_number, 'http://waialua.whyanbeel.net:9595/patterns/')
    result = sender.send(nil, nil, :size => 10)
    result.should be_true
  end

  it "should send a long message" do
    text = <<EOF
This is a really long message that should blow the message limit for the sms service. We want to be sure that the
service just truncates the message or joins it into two parts rather than throwing it back as an error. I'm interested
to know whether or not this works.
EOF
    sender = SmsSender.new(AppConfig.sms_test_number, 'http://waialua.whyanbeel.net:9595/patterns/', ERB.new(text))
    result = sender.send(nil, nil, :size => 10)
    result.should be_true
  end

  it "should send using the email template" do
    sender = SmsSender.new(AppConfig.sms_test_number, 'http://waialua.whyanbeel.net:9595/patterns/', EmailSender::DEFAULT_TEXT_TEMPLATE)
    result = sender.send(nil, nil, :size => 10)
    result.should be_true
  end
end
