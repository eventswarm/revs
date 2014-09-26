require File.join File.dirname(__FILE__), '..','spec_helper'
require 'revs/log_configuration'

EmailSender.smtp_defaults

describe 'LogConfiguration' do

  before(:all) do
    puts "Setting up log configuration"
    LogConfiguration.instance.setup  3600
  end

  after(:all) do
    puts "Stopping log configuration"
    LogConfiguration.instance.stop
    puts "Log configuration stopped"
  end

  it 'should establish the configuration' do
    conf = LogConfiguration.instance
    conf.should_not be_nil
    conf.channel.should_not be_nil
    conf.router.should_not be_nil
    conf.memory_monitor.should_not be_nil
    conf.window.should_not be_nil
  end

  it 'should send an alert on single error' do
    Log4JLogger.logger('test.log.configuration').error 'Error: test this log configuration'
  end

  it 'should send an alert on 5 warnings' do
    1.upto 5 do |idx|
      Log4JLogger.logger('test.log.configuration').warn "Warning: test this log configuration #{idx}"
    end
  end

  it 'should escalate on 5 errors' do
    1.upto 5 do |idx|
      Log4JLogger.logger('test.log.configuration').error "Error: test this log configuration #{idx}"
    end
  end

  it 'should abbreviate messages on 50 warnings' do
    1.upto 50 do |idx|
      Log4JLogger.logger('test.log.configuration').warn "Warning: test this log configuration #{idx}"
    end
  end

  it 'should classify messages' do
    1.upto 3 do |idx|
      Log4JLogger.logger('test.log.configuration1').warn "Warning: test this log configuration #{idx}"
    end
    1.upto 3 do |idx|
      Log4JLogger.logger('test.log.configuration2').warn "Warning: test this log configuration #{idx}"
    end
  end

  it 'should distinguish errors and warnings' do
    1.upto 3 do |idx|
      Log4JLogger.logger('test.log.configuration').warn "Warning: test this log configuration #{idx}"
    end
    1.upto 3 do |idx|
      Log4JLogger.logger('test.log.configuration').error "Error: test this log configuration #{idx}"
    end
  end

  it 'should always send for ALWAYS_REPORT actions' do
    Log4JLogger::ALWAYS_REPORT.info "Info: test the always report channel"
  end

  it 'should not rate limit ALWAYS_REPORT actions' do
    Log4JLogger::ALWAYS_REPORT.info "Info: test the always report channel once"
    Log4JLogger::ALWAYS_REPORT.info "Info: test the always report channel twice"
  end
end
