require 'revs'
require 'revs/jdo_event'
require_jar 'org.json', 'json'

java_import 'com.eventswarm.events.jdo.OrgJsonEvent'

#
# Reopen OrgJsonEvent to add some convenience methods for Ruby usage
#

class OrgJsonEvent < JdoEvent

  alias has? has

  #
  # Return the (Java) object whose name = the method name or nil if it is null, noting that the Java
  # object will be converted to a Ruby object according to the JRuby conventions
  #
  # Note that this function assumes an isNull method on the JSON object
  #
  def method_missing(m, *args, &block)
    if has? m.to_s
      get(m.to_s)
    else
      nil
    end
  end
end
