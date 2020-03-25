require 'spec_helper'
require_jar 'com.eventswarm', 'eventswarm'
require_jar 'com.eventswarm', 'eventswarm-social'
require 'revs/jdo_event'
require 'revs/org_json_event'
require 'revs/json_object'

java_import 'com.eventswarm.events.jdo.JdoHeader'
java_import 'com.eventswarm.social.events.JsonTweetEvent'
java_import 'com.eventswarm.events.jdo.JdoSource'

describe 'JdoEvent' do

  let(:now) {Time.now}
  let(:timestamp) {java.util.Date.new (now.to_time.to_f * 1000).to_i}
  let(:source) {JdoSource.new('JdoEventTest')}
  let(:id){'JdoEventTest1'}
  let(:header) {JdoHeader.new(timestamp, source, id)}
  let(:event) {JdoEvent.new(header, {})}
  let(:json_event) {OrgJsonEvent.new(header, JSONObject.new({:a => 1, 'b' => 'blah'}))}

  it 'should return the correct id' do
    event.id.should == id
  end

  it 'should return the correct event_id' do
    event.event_id.should == id
  end

  it 'should return the correct source' do
    event.id.should == id
  end

  it 'should return the correct date' do
    event.date.should.eql? now
  end

  it 'should be an event' do
    event.event?.should be_true
  end

  it 'should not be an activity' do
    event.activity?.should be_false
  end

  it 'should not be a JSON event' do
    event.json?.should be_false
  end

  it 'should not be an XML event' do
    event.xml?.should be_false
  end

  it 'should not be a log event' do
    event.log?.should be_false
  end

  it 'should not be a tweet event' do
    event.tweet?.should be_false
  end

  it 'should be a JSON event' do
    json_event.json?.should be_true
  end
end
