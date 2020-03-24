require_jar 'org.json', 'json'

java_import 'org.json.JSONObject'

#
# Reopening the JSONObject class to add some convenience methods
#
class JSONObject
  alias has? has

  #
  # Return the (Java) object whose name = the method name or nil if it is null, noting that the Java
  # object will be converted to a Ruby object according to the JRuby conventions
  #
  # Note that this function assumes an isNull method on the JSON object
  #
  def method_missing(m, *args, &block)
    if has? m.to_s
      opt(m.to_s)
    else
      super(m, *args, &block)
    end
  end
end
