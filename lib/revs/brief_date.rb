require 'time'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/date/calculations'

class BriefDate

  MERIDIAN = "%p"
  TIME_FMT = "%l:%M"
  THIS_WEEK_FMT = "%a " + TIME_FMT
  THIS_YEAR_FMT = "%e %b " + TIME_FMT
  FULL_FMT = "%e %b \`%y " + TIME_FMT

  def self.format(date)
    case
      when date.today?
        result = date.strftime(TIME_FMT)
      when date.this_week?
        result = date.strftime(THIS_WEEK_FMT)
      when date.this_year?
        result = date.strftime(THIS_YEAR_FMT)
      else
        result = date.strftime(FULL_FMT)
    end
    # Hate upper case meridian, and strip double spaces, if any
    result += date.strftime(MERIDIAN).downcase
    result.gsub(/  /, ' ')
  end

  def self.format_java(date)
    format(Time.at(date.getTime/1000))
  end
end

# extend time with some convenience tests
class Time
  def this_year?
    self.year == Time.now.year
  end

  def this_week?
    self > Time.now.weeks_ago(1)
  end
end