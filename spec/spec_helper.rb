require 'rubygems'
require 'rspec'
require 'bundler/setup'
require 'java'

top_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
lib_dir = File.expand_path(File.join(top_dir, 'lib'))
revs_dir = File.expand_path(File.join(lib_dir, 'revs'))

def add_to_load_path(*directories)
  directories.each do |directory|
    $LOAD_PATH.unshift(directory) unless $LOAD_PATH.include?(directory)
  end
end

add_to_load_path lib_dir, revs_dir

require 'revs'
require_jar 'log4j', 'log4j'
org.apache.log4j.BasicConfigurator.configure

require 'revs/app_config'
config_file = File.join(File.dirname(__FILE__), '..', 'lib', 'config', 'config.yml')
AppConfig.init config_file
