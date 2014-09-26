require 'spec_helper'
require 'revs/email_sender'

describe 'EmailSender' do

  let(:alerter) {double('alerter', :window => 5)}
  let(:pattern) {double('pattern', :name => 'my pattern')}
  let(:host)    {'mail4.qnetau.com'}
  let(:port)    {25}
  let(:user_name)  {'alerts@eventswarm.com'}
  let(:password) {'somerandompassword'}


  before(:each) do
    Mail.defaults do
      delivery_method :test
    end
  end

  it 'should set mail defaults with no params' do
    method = EmailSender.smtp_defaults
    method.settings[:address].should == AppConfig.smtp_host
    method.settings[:port].should == AppConfig.smtp_port
    method.settings[:user_name].should == AppConfig.smtp_user
    method.settings[:password].should == AppConfig.smtp_password
  end

  it 'should set mail defaults with params' do
    method = EmailSender.smtp_defaults host, port, user_name, password
    method.settings[:address].should == host
    method.settings[:port].should == port
    method.settings[:user_name].should == user_name
    method.settings[:password].should == password
  end

  it 'should render using the default subject template' do
    size = 10
    EmailSender::DEFAULT_SUBJECT_TEMPLATE.result(binding).should == "Eventswarm has matched your rule"
  end

  it 'should render using the default text template' do
    size = 10
    url = 'http://waialua.whyanbeel.net:9595/patterns'
    EmailSender::DEFAULT_TEXT_TEMPLATE.result(binding).should == <<EOF
Eventswarm has matched your rule.
For full results see http://waialua.whyanbeel.net:9595/patterns.

Regards,

The EventSwarm team
info@eventswarm.com
EOF
  end

  it 'should initialise without any templates' do
    sender = EmailSender.new('andyb@deontik.com', 'http://waialua.whyanbeel.net:9595/patterns')
    #To change this template use File | Settings | File Templates.
    sender.should_not be_nil
    sender.subject_template.should == EmailSender::DEFAULT_SUBJECT_TEMPLATE
    sender.text_template.should == EmailSender::DEFAULT_TEXT_TEMPLATE
  end

  describe 'Sending an test email' do
    include Mail::Matchers

    before(:each) do
      Mail::TestMailer.deliveries.clear
      sender = EmailSender.new('andyb@deontik.com', 'http://waialua.whyanbeel.net:9595/patterns')
      sender.send(nil, nil, {})
    end

    it {should have_sent_email.from('alerts@eventswarm.com')}
    it {should have_sent_email.to('andyb@deontik.com')}
    it {should have_sent_email.with_subject("Eventswarm has matched your rule")}
  end

  it 'should send a real email with username and password' do
    EmailSender.smtp_defaults
    sender = EmailSender.new('andyb@deontik.com', 'http://waialua.whyanbeel.net:9595/patterns')
    result = sender.send(nil, nil, :size => 10)
    result.should be_true # manual verification required
  end

  it 'should bcc if bcc is specified' do
    EmailSender.smtp_defaults
    EmailSender.bcc = 'drpump@me.com'
    sender = EmailSender.new('andyb@deontik.com', 'http://waialua.whyanbeel.net:9595/patterns')
    result = sender.send(nil, nil, :size => 10)
    result.should be_true # manual verification required
    EmailSender.bcc = nil # just to be sure: rspec seems to reset class vars, but the minitest framework doesn't
  end
end