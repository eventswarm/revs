require 'revs'
require_jar 'log4j', 'log4j'
require 'revs/triggers'

java_import 'com.eventswarm.channels.XmlHttpChannel'
java_import 'com.eventswarm.channels.XmlHttpEventFactory'
java_import 'java.net.InetAddress'
java_import 'java.net.InetSocketAddress'
java_import 'com.sun.net.httpserver.HttpServer'

#
# Set up an HTTP endpoint for receipt of XML events and make them available
#
# TODO: move this class into the revs library
#
class XmlStream
  include Log4JLogger

  # class to manage singleton XML http channel

  attr_reader :channel, :port, :factory

  class << self
    # Get an instance and use the supplied factory (implementing the EventSwarm FromXmlHttp interface) as the
    # default factory
    def instance(factory = nil, port = 0)
      if @instance.nil?
        factory = XmlHttpEventFactory.new if factory.nil?
        @instance = XmlStream.new(factory, port)
      end
      @instance
    end

    def register_action action
      Triggers.add instance.channel, action
    end

    def unregister_action action
      Triggers.un_add instance.channel, action
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
    logger.info "Stopping HTTP server"
    @server.stop 0 if running?
    @running = false
  end

  def start
    @server.start
    @running = true
  end

  private

  def initialize(factory, port)
    @running = false
    @factory = factory
    @channel = XmlHttpChannel.new factory
    # create and start an HTTPServer instance to feed in the HTTP requests
    address = InetSocketAddress.new(port)
    @server = HttpServer.create(address, 0)
    @port = @server.address.port
    logger.info("Starting HTTP server for XML requests")
    @server.createContext('/', @channel)
  end
end