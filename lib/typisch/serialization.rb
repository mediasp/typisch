require 'json'

module Typisch
  class JSONSerializer
    def initialize(type, options={})
      @type = type
      @options = {}
      @type_tag_key = (options[:type_tag_key] || '__class__').freeze
      @class_to_type_tag = options[:class_to_type_tag]
      @type_tag_to_class = options[:type_tag_to_class] || (@class_to_type_tag && @class_to_type_tag.invert)
    end

    def class_to_type_tag(klass)
      @class_to_type_tag ? @class_to_type_tag[klass] : klass.to_s
    end

    def serialize(value)
      serialize_to_jsonable(value).to_json
    end

    # http://work.tinou.com/2009/06/the-expression-problem-and-other-mysteries-of-life.html
    def serialize_to_jsonable(value, type=@type, seen_values={})
      raise Error::CyclicSerialization if seen_values[value]

      result = case type
      when Type::Date
        value.to_s

      when Type::Time
        value.iso8601

      when Type::Sequence
        seen_values[value] = true
        value.map {|v| serialize_to_jsonable(v, type.type, seen_values)}

      when Type::Tuple
        seen_values[value] = true
        type.types.zip(value).map {|t,v| serialize_to_jsonable(v,t,seen_values)}

      when Type::Object
        seen_values[value] = true
        result = {@type_tag_key => class_to_type_tag(value.class)}
        type.property_names_to_types.each do |prop_name, type|
          result[prop_name.to_s] = serialize_to_jsonable(value.send(prop_name), type, seen_values)
        end
        result

      when Type::Union
        # todo: a better way to backtrack during serialization of unions,
        # or maybe just ditch the untagged union idea which would avoid the need
        # for backtracking

        viable_types = type.alternative_types.select {|t| t.shallow_check_type(value)}
        type = if viable_types.length == 1
          viable_types.first
        else
          viable_types.find {|t| t === value}
        end
        serialize_to_jsonable(value, type, seen_values)

      when Type::Constructor # Numeric, Null, String, Boolean etc
        value

      else
        raise "Type #{type} not supported for serialization"
      end

      seen_values.delete(value)

      result
    end
  end
end
