require 'spec_helper'
require 'revs'
require 'revs/twitter_connection'
require 'revs/app_config'
require 'eventswarm-social-jar'

java_import 'com.eventswarm.eventset.EventSet'

describe 'TwitterConnection' do

  it 'should create a singleton instance' do
    TwitterConnection.instance.should_not be_nil
  end

  it 'should deliver query results' do
    results = EventSet.new
    TwitterConnection.instance.query '#news', nil, results
    results.should_not be_nil
    p "Query returned #{results.size} results"
    (results.size > 0).should be_true
  end

  it 'should respect the last setting' do
    # TODO: seems that the 'last' setting is unreliable
    results1 = EventSet.new
    TwitterConnection.instance.query '#news', nil, results1
    p "First query returned #{results1.size} results"
    results2 = EventSet.new
    TwitterConnection.instance.query '#news', results1.last, results2
    p "Second query returned #{results2.size} events"
    if results2.size == 0
      true.should be_true
    else
      dupes = []
      results2.each do |event|
        dupes << event.tweetId if results1.contains(event)
      end
      p "Tweets with ids [#{dupes.join ', '}] are duplicates"
      dupes.length.should == 0
    end
  end

  it 'should deliver to multiple actions' do
    results1 = EventSet.new
    results2 = EventSet.new
    TwitterConnection.instance.query '#news', nil, results1, results2
    p "Query returned #{results1.size} results"
    (results1.size == results2.size).should be_true, "results1.size() = #{results1.size}; results2.size = #{results2.size}"
  end
end