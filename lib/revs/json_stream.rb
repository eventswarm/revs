require 'revs'
require 'revs/log4_j_logger'
require 'revs/triggers'
require 'json-jar'

java_import 'com.eventswarm.channels.JsonHttpChannel'
java_import 'com.eventswarm.channels.JsonHttpEventFactory'
java_import 'java.net.InetAddress'
java_import 'java.net.InetSocketAddress'
java_import 'com.sun.net.httpserver.HttpServer'


#
# Set up an HTTP endpoint for receipt of JSON events and make them available
#
class JsonStream
  include Log4JLogger

  DEFAULT_PORT = 3333
  BASE_PATH = '/'

  attr_reader :port, :factory

  class << self
    # Get an instance and use the supplied factory (implementing the EventSwarm FromJsonHttp interface) as the
    # default factory
    def instance(factory = nil, port = DEFAULT_PORT)
      if @instance.nil?
        factory = JsonHttpEventFactory.new if factory.nil?
        @instance = JsonStream.new(factory, port)
      end
      @instance
    end

    # register an action, optionally specifying a URL path relative to the application root (including leading '/')
    def register_action(action, path=BASE_PATH)
      @instance.register_action action, path
    end

    # unregister an action, optionally specifying a URL path relative to the application root (including leading '/')
    def unregister_action(action, path=BASE_PATH)
      @instance.unregister_action action, path
    end

    def state
      state = {'Status' => "#{running? ? 'running' : 'stopped'}",
               'Server port' => "#{instance.port}"}
      unless instance.channel.nil?
        state.merge!({'Event count' => "#{instance.channel.count}",
                      'Error count' => "#{instance.channel.error_count}"})
      end
      state
    end

    def start
      instance.start
    end

    def stop
      @instance.stop unless @instance.nil?
    end

    # get rid of the instance
    def nuke
      unless @instance.nil?
        @instance.stop
        @instance = nil
      end
    end

    def running?
      instance.running?
    end
  end

  def running?
    @running
  end


  def stop
    @server.stop 0
    @running = false
  end

  def start
    @server.start
    @running = true
  end

  # method to return the default channel
  def channel
    @channels[BASE_PATH]
  end

  def register_action(action, path)
    if @channels[path].nil?
      @channels[path] = JsonHttpChannel.new @factory
      @server.createContext(path, @channels[path])
    end
    Triggers.add @channels[path], action
  end

  # removes a registered action
  def unregister_action(action, path)
    unless @channels[path].nil?
      Triggers.un_add @channels[path], action
    end
  end

  private

  def initialize(factory, port)
    @running = false
    @factory = factory
    @port = port
    # create default channel as a fall-through for unmonitored paths
    @channels = {BASE_PATH => JsonHttpChannel.new(factory)}
    # create and start an HTTPServer instance to feed in the HTTP requests
    address = InetSocketAddress.new(port)
    @server = HttpServer.create(address, 0)
    p "Starting HTTP server for JSON requests"
    logger.info("Starting HTTP server for JSON requests")
    @server.createContext(BASE_PATH, channel)
  end

end
