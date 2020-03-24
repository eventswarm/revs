require 'spec_helper'
require 'rspec/expectations'
require 'rspec/wait'
require 'revs'
require 'revs/tweet_stream'
require 'revs/add_action'

describe 'TweetStream' do

  it 'should create a singleton instance' do
    TweetStream.create
    TweetStream.connected?.should be_false
  end

  it 'should not connect if nothing to track' do
    TweetStream.create
    TweetStream.connect
    TweetStream.connected?.should be_false
  end

  it 'should connect if something to track' do
    TweetStream.create
    TweetStream.add_filters(['@smon110', 'smon110'], ['#news'])
    TweetStream.connect
    sleep(5) # need to wait for it to finish connectings
    expect(TweetStream.connected?).to be_true
    TweetStream.disconnect
  end

  it 'should receive tweets' do
    TweetStream.create
    TweetStream.add_filters(['@smon110', 'smon110'], ['#news'])
    TweetStream.register_action AddAction.new{|trigger, event| add_action trigger, event}
    TweetStream.connect
    sleep(5)
    expect(TweetStream.count).to be > 0
    TweetStream.disconnect
  end

  it 'should map user handles to ids' do
    ids = TweetStream.get_user_ids ['@smon110']
    p ids
    ids.length.should == 1
  end

  def add_action(trigger, event)
    @count ||= 0
    p "Received trigger: #{trigger} and event: #{event}"
    @count = @count + 1
  end
end