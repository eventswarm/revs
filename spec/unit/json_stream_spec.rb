require File.join File.dirname(__FILE__), '..','spec_helper'
require 'json-jar'
require 'net/http'
require 'revs'
require 'revs/app_config'
AppConfig.init File.join(File.dirname(__FILE__), '..', 'fixtures', 'config.yml')
require 'revs/json_stream'

java_import 'com.eventswarm.events.jdo.JdoHeader'
java_import 'com.eventswarm.events.jdo.JdoSource'
java_import 'com.eventswarm.events.jdo.OrgJsonPart'
java_import 'com.eventswarm.AddEventAction'
java_import 'com.eventswarm.channels.JsonHttpEventFactory'
java_import 'com.eventswarm.util.EventList'

describe 'JsonStream' do

  let(:simple_object_path)  {File.join(File.dirname(__FILE__), '..', 'fixtures', 'single_object.json')}
  let(:long_text_object_path) {File.join(File.dirname(__FILE__), '..', 'fixtures', 'long_text_object.json')}
  let(:whitespace_object_path) {File.join(File.dirname(__FILE__), '..', 'fixtures', 'single_object_with_whitespace.json')}
  let(:long_text_truncated) {'I need to ensure that there are more than 150 characters in this particular text string so I will have to make it very, very, long. Can you tell me...'}
  let(:events) {EventList.new()}

  before do
    JsonStream.nuke
  end

  it 'should create new instance with factory and port' do
    factory = JsonHttpEventFactory.new
    instance = JsonStream.new factory, 3334
    instance.should_not be_nil
    instance.port.should == 3334
    instance.factory.should == factory
  end

  it 'should create new singleton with factory' do
    factory = JsonHttpEventFactory.new
    instance = JsonStream.instance factory
    instance.should_not be_nil
    instance.factory.should == factory
  end

  it 'should create new singleton without factory' do
    instance = JsonStream.instance
    instance.should_not be_nil
    instance.factory.should_not be_nil
  end

  it 'should send single event' do
    JsonStream.start
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    response = http.request_post '/', File.read(simple_object_path)
    JsonStream.stop
    p response.to_s
    response.should be_a Net::HTTPSuccess
  end

  it 'send single event with whitespace' do
    JsonStream.start
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    response = http.request_post '/', File.read(whitespace_object_path)
    JsonStream.stop
    p response.to_s
    response.should be_a Net::HTTPSuccess
  end

  it 'should collect received event' do
    JsonStream.start
    JsonStream.register_action events
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    data = File.read(simple_object_path)
    response = http.request_post '/', data
    JsonStream.stop
    response.should be_a Net::HTTPSuccess
    events.should be_a Java::java.util.List
    events.count.should == 1
    p "Events: #{events}"
    # TODO: work out why rspec chokes on the following
    #events[0].should be_a Java::com.eventswarm.events.Event
  end

  it 'should collect received event on unregistered path' do
    JsonStream.start
    JsonStream.register_action events
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    data = File.read(simple_object_path)
    response = http.request_post '/some_path', data
    JsonStream.stop
    response.should be_a Net::HTTPSuccess
    events.should be_a Java::java.util.List
    events.count.should == 1
    p "Events: #{events}"
  end

  it 'should collect received event on registered path' do
    JsonStream.start
    JsonStream.register_action events, '/some_path'
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    data = File.read(simple_object_path)
    response = http.request_post '/some_path', data
    JsonStream.stop
    response.should be_a Net::HTTPSuccess
    events.should be_a Java::java.util.List
    events.count.should == 1
    p "Events: #{events}"
  end

  it 'should not collect on default path when specific path is registered' do
    JsonStream.start
    JsonStream.register_action events
    some_path = '/some_path'
    for_some_path = EventList.new()
    JsonStream.register_action for_some_path, some_path
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    data = File.read(simple_object_path)
    response = http.request_post some_path, data
    JsonStream.stop
    response.should be_a Net::HTTPSuccess
    events.should be_a Java::java.util.List
    events.count.should == 0
    for_some_path.count.should == 1
    p "Events: #{events}"
    p "Some path events #{for_some_path}"
  end

  it 'send and collect multiple events in single request' do
    JsonStream.start
    JsonStream.register_action events
    http = Net::HTTP.start 'localhost', JsonStream.instance.port
    data = File.read(simple_object_path) + File.read(long_text_object_path)
    response = http.request_post '/', data
    JsonStream.stop
    response.should be_a Net::HTTPSuccess
    events.count.should == 2
  end
end
