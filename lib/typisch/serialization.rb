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

    def serialize_already_encountered_pair(value, type, existing_serialization)
      raise SerializationError, "cyclic object / type graph when serializing"
    end

    # http://work.tinou.com/2009/06/the-expression-problem-and-other-mysteries-of-life.html
    def serialize_to_jsonable(value, type=@type, existing_serializations={})
      existing = existing_serializations[[type, value]]
      return serialize_already_encountered_pair(value, type, existing) if existing

      result = case type
      when Type::Date
        value.to_s

      when Type::Time
        value.iso8601

      when Type::Sequence
        if type.slice
          slice = value[type.slice]
          existing_serializations[[type, value]] = result = {
            @type_tag_key => class_to_type_tag(value.class),
            'range_start' => type.slice.begin
          }
          result['items'] = slice.map {|v| serialize_to_jsonable(v, type.type, existing_serializations)} if slice
          result['total_items'] = value.length if type.total_length
          result
        else
          result = existing_serializations[[type, value]] = []
          value.each {|v| result << serialize_to_jsonable(v, type.type, existing_serializations)}
          result
        end

      when Type::Tuple
        result = existing_serializations[[type, value]] = []
        type.types.zip(value).each {|t,v| result << serialize_to_jsonable(v,t,existing_serializations)}
        result

      when Type::Object
        result = existing_serializations[[type, value]] = {@type_tag_key => class_to_type_tag(value.class)}
        type.property_names_to_types.each do |prop_name, type|
          result[prop_name.to_s] = serialize_to_jsonable(value.send(prop_name), type, existing_serializations)
        end
        result

      when Type::Union
        type = type.alternative_types.find {|t| t.shallow_check_type(value)}
        raise SerializationError, "No types in union #{type} matched #{value.inspect}, could not serialize" unless type
        serialize_to_jsonable(value, type, existing_serializations)

      when Type::Constructor # Numeric, Null, String, Boolean etc
        value

      else
        raise SerializationError, "Type #{type} not supported for serialization of #{value.inspect}"
      end

      result
    end
  end
end
