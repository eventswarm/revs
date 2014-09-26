require File.join File.dirname(__FILE__), '..','spec_helper'
require 'net/http'
require 'revs'
require 'revs/xml_stream'

java_import 'com.eventswarm.events.jdo.JdoHeader'
java_import 'com.eventswarm.events.jdo.JdoSource'
java_import 'com.eventswarm.events.jdo.OrgJsonPart'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.channels.XmlHttpEventFactory'
java_import 'com.eventswarm.util.EventList'

describe 'XmlStream' do

  let(:simple_object_path)  {File.join(File.dirname(__FILE__), '..', 'fixtures', 'single_object.xml')}
  let(:long_text_object_path) {File.join(File.dirname(__FILE__), '..', 'fixtures', 'long_text_object.xml')}
  let(:whitespace_object_path) {File.join(File.dirname(__FILE__), '..', 'fixtures', 'single_object_with_whitespace.xml')}
  let(:long_text_truncated) {'I need to ensure that there are more than 150 characters in this particular text string so I will have to make it very, very, long. Can you tell me...'}
  let(:events) {EventList.new()}

  before do
    XmlStream.nuke
  end

  it 'should create new instance with factory and port' do
    factory = XmlHttpEventFactory.new
    instance = XmlStream.new factory, 3335
    instance.should_not be_nil
    instance.port.should == 3335
    instance.factory.should == factory
  end

  it 'should create new singleton with factory' do
    factory = XmlHttpEventFactory.new
    instance = XmlStream.instance factory
    instance.should_not be_nil
    instance.port.should == 3334
    instance.factory.should == factory
  end

  it 'should create new singleton without factory' do
    instance = XmlStream.instance
    instance.should_not be_nil
    instance.port.should == 3334
    instance.factory.should_not be_nil
  end

  it 'send single event' do
    XmlStream.start
    http = Net::HTTP.start 'localhost', 3334
    response = http.request_post '/', File.read(simple_object_path)
    XmlStream.stop
    p response.to_s
    response.should be_a Net::HTTPSuccess
  end

  it 'send single event with whitespace' do
    XmlStream.start
    http = Net::HTTP.start 'localhost', 3334
    response = http.request_post '/', File.read(whitespace_object_path)
    XmlStream.stop
    p response.to_s
    response.should be_a Net::HTTPSuccess
  end

  it 'should collect received event' do
    XmlStream.start
    XmlStream.register_action events
    http = Net::HTTP.start 'localhost', 3334
    data = File.read(simple_object_path)
    response = http.request_post '/', data
    XmlStream.stop
    response.should be_a Net::HTTPSuccess
    events.should be_a Java::java.util.List
    events.count.should == 1
    p "Events: #{events}"
    # TODO: work out why rspec chokes on the following
    #events[0].should be_a Java::com.eventswarm.events.Event
  end

  pending 'send and collect multiple events in single request' do
    XmlStream.start
    XmlStream.register_action events
    http = Net::HTTP.start 'localhost', 3334
    data = File.read(simple_object_path) + File.read(long_text_object_path)
    response = http.request_post '/', data
    XmlStream.stop
    response.should be_a Net::HTTPSuccess
    events.count.should == 2
  end
end
