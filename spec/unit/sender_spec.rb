require 'spec_helper'
require 'revs'
require 'revs/sender'
require 'json-jar'
require 'java-uuid-generator-jar'
require 'log4_j_logger'

java_import 'com.eventswarm.events.jdo.JdoHeader'
java_import 'com.eventswarm.events.jdo.JdoSource'
java_import 'com.eventswarm.events.jdo.OrgJsonPart'
java_import 'com.eventswarm.events.jdo.OrgJsonEvent'
java_import 'com.eventswarm.eventset.DiscreteTimeWindow'
java_import 'java.text.SimpleDateFormat'

class TestSender
  include Sender

  attr_accessor :myvars

  def send(trigger, event, others={})
    @myvars = nil
    super(trigger, event, others) do |vars|
      # if the super actually sends, vars will be defined
      @myvars = vars
    end
  end
end

def new_event
  format = SimpleDateFormat.new 'HH:mm:ss.SSS'
  header = JdoHeader.new Time.now.to_i * 1000, 'TestSender'
  p "New event date is #{format.format header.timestamp}"
  json = OrgJsonPart.new ('{"a": 1, "b": 2}')
  OrgJsonEvent.new header, json
end

describe 'Sender' do
  before do
    logger = Java::org::apache::log4j::Logger.getLogger(DiscreteTimeWindow.java_class)
    logger.setLevel(Java::org::apache::log4j::Level::DEBUG)
  end

  it 'should include extra parameters in the binding' do
    instance = TestSender.new
    result = instance.send nil, 'event1', :blah => 1
    result.should be_true
    instance.myvars.eval('blah').should == 1
  end

  it 'should default the url' do
    instance = TestSender.new
    instance.default_url = 'http://localhost'
    result = instance.send nil, 'event1', :blah => 1
    result.should be_true
    instance.myvars.eval('url').should == 'http://localhost'
  end

  it 'should override the default url' do
    instance = TestSender.new
    instance.default_url = 'http://localhost'
    result = instance.send nil, 'event1', :blah => 1, :url => 'http://example.com'
    result.should be_true
    instance.myvars.eval('url').should == 'http://example.com'
  end

  it 'should send the first event' do
    instance = TestSender.new
    result = instance.send nil, 'event1'
    result.should be_true
    instance.myvars.should_not be_nil
  end

  it 'should not send the second event (count > MAX)' do
    instance = TestSender.new
    instance.send nil, 'event1'
    result = instance.send nil, 'event2'
    result.should be_false
    instance.myvars.should be_nil
  end

  it 'should send the second event after a reset' do
    instance = TestSender.new
    instance.send nil, 'event1'
    instance.reset
    result = instance.send nil, 'event2'
    result.should be_true
    instance.myvars.should_not be_nil
  end

  it 'should not send the second event within the rate limit period' do
    instance = TestSender.new
    instance.limit 10
    instance.send nil, new_event
    result = instance.send nil, new_event
    result.should be_false
    instance.myvars.should be_nil
  end

  it 'should permit the second event outside the rate limit period' do
    instance = TestSender.new
    instance.limit 1
    instance.send nil, new_event
    sleep(2)
    result = instance.send nil, new_event
    result.should be_true
    instance.myvars.should_not be_nil
  end

  it 'should permit the next event outside the rate limit period' do
    instance = TestSender.new
    instance.limit 1
    instance.send nil, new_event
    instance.send nil, new_event
    instance.myvars.should be_nil
    sleep(2)
    result = instance.send nil, new_event
    result.should be_true
    instance.myvars.should_not be_nil
  end
end