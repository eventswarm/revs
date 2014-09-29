require 'yaml'
require 'revs/log4_j_logger'

class AppConfig
  include Log4JLogger

  class << self

    def init(override_path, default_path = File.join(File.dirname(__FILE__), '..', 'config','templates','config.yml'))
      @default_path = default_path
      @override_path = override_path
    end

    def reload
      @default_config = YAML::load File.open(@default_path)
      begin
        @config = YAML::load File.open(@override_path)
      rescue
        Log4JLogger.logger('com.eventswarm.revs.AppConfig').warn 'Could not load localised config, using default config'
        @config = @default_config
      end
    end

    # define getter for base url that pulls it from config unless otherwise set
    def base_url
      @base_url || value('base_url')
    end

    # provide setter for base url that allows it to be set (e.g. based on actual urls from user requests)
    def base_url=(val)
      @base_url = val
    end

    def method_missing(m, *args, &block)
      value(m.to_s)
    end

    def value(key)
      reload if @default_config.nil?
      # want to return nil if the override config has explicitly set the value to nil
      if @config.has_key? key
        @config[key]
      else
        @default_config[key]
      end
    end
  end
end
