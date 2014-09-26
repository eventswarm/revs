require 'eventswarm-jar'
require 'revs/tweet_pattern'
require 'revs/tweet_clouds'
require 'revs/persistence'

java_import 'com.eventswarm.eventset.LastNWindow'
java_import 'com.eventswarm.eventset.DiscreteTimeWindow'
java_import 'com.eventswarm.util.IntervalUnit'
java_import 'com.eventswarm.abstractions.ClassValueRetriever'
java_import 'com.eventswarm.expressions.SequenceExpression'
java_import 'com.eventswarm.expressions.ANDExpression'
java_import 'com.eventswarm.expressions.EventLogicalOR'
java_import 'com.eventswarm.expressions.ExpressionMatchSet'
java_import 'com.eventswarm.expressions.MatchCountExpression'
java_import 'com.eventswarm.powerset.EventKey'
java_import 'com.eventswarm.powerset.ExpressionCreator'
java_import 'com.eventswarm.powerset.HashPowerset'
java_import 'com.eventswarm.powerset.PowersetExpression'
java_import 'com.eventswarm.util.logging.SizeMonitor'

class Pattern
  include Log4JLogger
  include ExpressionCreator

  OR = 'OR'
  AND = 'AND'
  SEQUENCE = 'THEN'
  CONJUNCT_TYPES = [OR, AND, SEQUENCE]

  CORRELATE_NONE = 'none'

  TWEET = 'tweet'
  STREAMS = [TWEET]

  MATCH_LIMIT = 100

  class << self; attr_reader :patterns end
  @patterns = {}

  #TODO: handle the re-naming of a pattern, probably using UUIDs

  attr_accessor :json, :alerters, :filter, :window, :results, :clouds, :enabled

  def initialize(json, max_results = MATCH_LIMIT)
    @json = json
    @parsed_json = JSON.parse(json, :symbolize_names => true)
    @alerters = {}
    @max_results = max_results
    @create_count = 0
    logger.debug "Parsed JSON: #{@parsed_json.inspect}"
    @enabled = true
    construct
  end

  def enabled?
    @enabled
  end

  def construct
    logger.debug "Creating parts"
    @parts = make_parts
    logger.debug "Creating match window of size #{window_size} #{window_units}"
    @window = DiscreteTimeWindow.new window_units, window_size
    case
      when conjunct?
        logger.debug "Conjunct expression, creating logical expression"
        @expression = make_conjunct
        @results = @expression.matches
        Triggers.add_remove @window, @expression
        # All events evaluated much match the filter of at least one component
        @filter = EventMatchPassThruFilter.new ORMatcher.new(@parts.collect{|part| part.matcher})
      when singleton?
        logger.info "Singleton expression, creating standalone expression"
        if match_count > 1
          logger.info "Wrapping expression in match counter that fires after #{match_count} matches"
          @expression = MatchCountExpression.new @parts[0].create_expression, match_count
        else
          @expression = @parts[0].create_expression
        end
        Triggers.add_remove @window, @expression
        @results = @expression.matches
        Triggers.match(@expression, tweets) if @parts[0].type == Pattern::TWEET
        @filter = EventMatchPassThruFilter.new @parts[0].matcher
      else
        logger.warn "Unrecognised expression: #{@parsed_json}"
    end
    # attach the filter to the window
    Triggers.add @filter, @window

    # maintain clouds for associated tweet events
    unless tweet_parts.nil? || tweet_parts.empty?
      logger.debug "Creating clouds for #{name}"
      @clouds = TweetClouds.new(tweets)
    end

    # monitor the size of the window and the results
    # TODO: define a window monitor that is appropriate for the expression
    @window_monitor = SizeMonitor.new @window, 1000, "#{name} window"
    @results_monitor = SizeMonitor.new @results, 100, "#{name} results", 200, 300
  end

  #
  # Called by a PowersetExpression (Java) to create a new expression instance
  #
  def new_expression(owner)
    @create_count += 1
    logger.info "Have created #{@create_count} expressions for #{self}" if @create_count % 10 == 0
    # can limit the number of matches held to 1 because we're catching them in a downstream match set
    make_conjunct 1, true
  end

  def make_conjunct(limit = MATCH_LIMIT, tail = false)
    case conjunct
      when OR
        logger.info 'Creating OR expression'
        EventLogicalOR.new create_expressions(tail), limit
      when AND
        logger.info 'Creating AND expression'
        ANDExpression.new create_expressions(tail)
      when SEQUENCE
        logger.info 'Creating Sequence expression'
        SequenceExpression.new create_expressions(tail)
      else
        logger.warn 'Unknown conjunct in expression'
    end
  end

  def make_pset(retriever)
    logger.debug "Creating powerset and associated powerset expression"
    @pset = HashPowerset.new retriever
    @pset_expression = PowersetExpression.new self
    Triggers.add_pset @pset, @pset_expression
    Triggers.remove_pset @pset, @pset_expression
    @results = LastNWindow.new(MATCH_LIMIT)
    Triggers.complex_match @pset_expression, ExpressionMatchSet.new(@results)
  end

  def make_parts(pset=nil)
    @parsed_json[:patterns].collect {|component| make_part component }
  end

  def clear
    # reconstruct the pattern rather than just clearing: causing too many anomalies
    construct
    alerters.values.each {|alerter| alerter.setup_monitor self}
  end

  # Return a pattern object created from the supplied JSON
  def make_part(component)
    case component[:type]
      when TWEET
        logger.info 'Creating tweet part'
        TweetPattern.new component
      else
        logger.warn "Unknown part type: #{component[:type]}"
    end
  end

  def create_expressions(tail=false)
    @parts.collect do |part|
      expression = part.create_expression(tail)
      Triggers.match(expression, tweets) if part.type == Pattern::TWEET
      expression
    end
  end

  def correlate_key
    @parsed_json[:correlate_key]
  end

  def correlate?
    !(conjunct == OR || correlate_key.nil? || correlate_key == CORRELATE_NONE)
  end

  def singleton?
    @parsed_json[:patterns].size == 1
  end

  def conjunct?
    @parsed_json[:patterns].size > 1
  end

  def has_tweet_parts?
    true unless tweet_parts.nil? || tweet_parts.empty?
  end

  def tweet_parts
    @parts.select{|part| part.type == TWEET}
  end

  def tweets
    @tweets ||= ExpressionMatchSet.new(LastNWindow.new(@max_results))
  end

  # Sometimes we need to replay tweets if the pattern is reconstructed but we want to retain matched tweets
  def replay_tweets
    tweets.each {|event| Triggers.execute_add tweets, @window, event}
  end

  def name
    @parsed_json[:name]
  end

  def window_size
    Integer @parsed_json[:window][:size]
  end

  def match_count
    field = @parsed_json[:match_count]
    field.nil? ? 0 : (Integer field)
  end

  def window_units
    case @parsed_json[:window][:units]
      when 'seconds'
        IntervalUnit::SECONDS
      when 'minutes'
        IntervalUnit::MINUTES
      when 'hours'
        IntervalUnit::HOURS
      when 'days'
        IntervalUnit::DAYS
      when 'weeks'
        IntervalUnit::WEEKS
      else
        logger.error "Unrecognised window units #{@parsed_json[:window][:units]}"
    end
  end

  def add_alerter(alerter)
    @alerters[alerter.id] = alerter
  end

  def remove_alerter(alerter)
    @alerters.delete(alerter.id)
  end

  def conjunct
    if @parsed_json[:cardinality] == '1'
      OR
    else
      if @parsed_json[:ordering] == 'sequence'
        SEQUENCE
      else
        AND
      end
    end
  end

  # return an array of pattern strings, one for each pattern component
  def pattern_strings
    @parts.collect{|part| part.to_s}
  end

  class << self

    #TODO: deal with names being normalised to the same filename
    def make_filename(name)
      File.join(Persistence.patterns_dir, name.gsub(/[^0-9A-z.\-]/, '_'))
    end

    # add a pattern to our set and save the json on disk so it can be reloaded on restart
    # note that this does not register the pattern expression against any streams
    def add(pattern)
      Log4JLogger.logger(self.name).info "Adding pattern: #{pattern.name}"
      @patterns[pattern.name] = pattern
      pattern
    end

    def save(pattern)
      handle = File.open(make_filename(pattern.name), 'w')
      handle.write(pattern.json)
      pattern
    end

    # load all saved patterns from disk, optionally specifying the result buffer size for each pattern
    def load_all(max_results = 200)
      Dir.foreach(Persistence.patterns_dir) do | file |
        path = File.join(Persistence.patterns_dir, file)
        #begin
        add(Pattern.new(File.read(path), max_results)) if File.stat(path).file?
        #rescue Exception => e
        #  puts "Problem loading #{path}: #{e}"
        #end
      end
    end

    # delete a pattern from our set and delete the associated json on disk
    # note that this does not unregister the pattern expression from any streams
    def delete(name)
      unless @patterns[name].nil?
        File.delete(make_filename(name))
        @patterns.delete(name)
      end
    end
  end
end