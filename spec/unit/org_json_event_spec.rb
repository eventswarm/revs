require 'spec_helper'
require 'revs'
require 'json-jar'
require 'revs/org_json_event'
require 'revs/json_object'

java_import 'com.eventswarm.events.jdo.JdoHeader'

describe 'OrgJsonEvent' do
  let(:hash) {{'a' => 1, 'b' => 'blah', 'c' => {'d' => 1.0}}}
  let(:json_event){OrgJsonEvent.new(JdoHeader.get_local_header, JSONObject.new(hash))}

  #before do
  #  puts "#{json_event.json_string}"
  #end

  it 'should have an "a" attribute' do
    json_event.has?('a').should be_true
  end

  it 'should have an "b" attribute' do
    json_event.has?('b').should be_true
  end

  it 'should have an "c" attribute' do
    json_event.has?('c').should be_true
  end

  it 'should have an "c/d" attribute' do
    json_event.has?('c/d').should be_true
  end

  it 'should get an integer' do
    json_event.a.should == 1
  end

  it 'should get an string' do
    json_event.b.should == 'blah'
  end

  it 'should get a JSON object' do
    json_event.c.java_kind_of?(org.json.JSONObject).should be_true
  end

  it 'should get a nested object' do
    json_event.c.d.should == 1.0
  end

  it 'should have access to Ruby methods on JdoEvent' do
    json_event.date.should be_a_kind_of(Time)
  end
end
