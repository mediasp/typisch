require 'json'
require 'yaml'

module Typisch
  class Serializer
    def initialize(type)
      @type = type
    end

    def serialize(data)
      serialize_type(data, @type, {})
    end

  private

    # http://work.tinou.com/2009/06/the-expression-problem-and-other-mysteries-of-life.html
    def serialize_type(value, type, existing_serializations={})
      existing = existing_serializations[[type, value]] and
        return serialize_already_encountered_pair(value, type, existing)

      case type
      when Type::Sequence then if type.slice
        serialize_slice(value, type, existing_serializations={})
      else
        serialize_sequence(value, type, existing_serializations={})
      end
      when Type::Tuple    then serialize_tuple(value, type, existing_serializations)
      when Type::Object   then serialize_object(value, type, existing_serializations)
      when Type::Union    then serialize_union(value, type, existing_serializations)
      when Type::Constructor then serialize_value(value) # Numeric, Null, String, Boolean etc
      else raise SerializationError, "Type #{type} not supported for serialization of #{value.inspect}"
      end
    end

    def serialize_already_encountered_pair(value, type, existing_serialization)
      raise SerializationError, "cyclic object / type graph when serializing"
    end
  end

  class JsonableSerializer < Serializer
    def initialize(type, options={})
      super(type)
      @type_tag_key = (options[:type_tag_key] || '__class__').freeze
      @class_to_type_tag = options[:class_to_type_tag]
      @type_tag_to_class = options[:type_tag_to_class] || (@class_to_type_tag && @class_to_type_tag.invert)
    end

    def class_to_type_tag(klass)
      @class_to_type_tag ? @class_to_type_tag[klass] : klass.to_s
    end

    def serialize_slice(value, type, existing_serializations)
      slice = value[type.slice]
      existing_serializations[[type, value]] = result = {
        @type_tag_key => class_to_type_tag(value.class),
        'range_start' => type.slice.begin
      }
      result['items'] = slice.map {|v| serialize_type(v, type.type, existing_serializations)} if slice
      result['total_items'] = value.length if type.total_length
      result
    end

    def serialize_sequence(value, type, existing_serializations)
      result = existing_serializations[[type, value]] = []
      value.each {|v| result << serialize_type(v, type.type, existing_serializations)}
      result
    end

    def serialize_tuple(value, type, existing_serializations)
      result = existing_serializations[[type, value]] = []
      type.types.zip(value).each {|t,v| result << serialize_type(v,t,existing_serializations)}
      result
    end

    def serialize_object(value, type, existing_serializations)
      result = existing_serializations[[type, value]] = {@type_tag_key => class_to_type_tag(value.class)}
      type.property_names_to_types.each do |prop_name, type|
        result[prop_name.to_s] = serialize_type(value.send(prop_name), type, existing_serializations)
      end
      result
    end

    def serialize_union(value, type, existing_serializations)
      type = type.alternative_types.find {|t| t.shallow_check_type(value)}
      raise SerializationError, "No types in union #{type} matched #{value.inspect}, could not serialize" unless type
      serialize_type(value, type, existing_serializations)
    end

    def serialize_value(value)
      case value
      when ::Date then value.to_s
      when ::Time then value.iso8601
      else value
      end
    end
  end

  class JSONSerializer < JsonableSerializer
    def serialize(value)
      super(value).to_json
    end
  end

  class YAMLSerializer < JsonableSerializer
    def serialize(value)
      super(value).to_yaml
    end

    # YAML can cope with these!
    def serialize_already_encountered_pair(value, type, existing_serialization)
      existing_serialization
    end

    def serialize_object(value, type, existing_serializations)
      result = existing_serializations[[type, value]] = YAML::PrivateType.new(class_to_type_tag(value.class), hash={})
      type.property_names_to_types.each do |prop_name, type|
        hash[prop_name.to_s] = serialize_type(value.send(prop_name), type, existing_serializations)
      end
      result
    end

    def serialize_slice(value, type, existing_serializations)
      slice = value[type.slice]
      result = existing_serializations[[type, value]] = YAML::PrivateType.new(class_to_type_tag(value.class), hash={
        'range_start' => type.slice.begin
      })
      hash['items'] = slice.map {|v| serialize_type(v, type.type, existing_serializations)} if slice
      hash['total_items'] = value.length if type.total_length
      result
    end

    def serialize_value(value)
      value
    end
  end
end
