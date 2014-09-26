#
# Module to manage files and directories associated with saved state of the application
#
# We assume that we're either in rackup or in Tomcat, where the Java 'catalina.base' property is defined.
#
java_import 'java.lang.System'

module Persistence
  ROOT_DIR_PROPERTY = 'catalina.base'

  def self.root_dir
    @root_dir ||= System.getProperty(ROOT_DIR_PROPERTY) || File.join(File.dirname(__FILE__), '..')
  end

  def self.data_dir
    if @data_dir.nil?
      @data_dir = File.join(root_dir, 'data')
      Dir.mkdir @data_dir unless Dir.exist? @data_dir
    end
    @data_dir
  end

  def self.patterns_dir
    if @patterns_dir.nil?
      @patterns_dir = File.join(data_dir, 'patterns');
      Dir.mkdir @patterns_dir unless Dir.exist? @patterns_dir
    end
    @patterns_dir
  end

  def self.alerters_dir
    if @alerters_dir.nil?
      @alerters_dir = File.join(data_dir, 'alerters');
      Dir.mkdir @alerters_dir unless Dir.exist? @alerters_dir
    end
    @alerters_dir
  end
end
