require 'json'
require 'yaml'

module Typisch
  class Serializer
    def initialize(type)
      @type = type
    end

    def serialize(data)
      serialize_type(data, @type)
    end

  private

    # http://work.tinou.com/2009/06/the-expression-problem-and-other-mysteries-of-life.html
    def serialize_type(value, type, *args)
      case type
      when Type::Map      then serialize_map(value, type, *args)
      when Type::Sequence then if type.slice
        serialize_slice(value, type, *args)
      else
        serialize_sequence(value, type, *args)
      end
      when Type::Tuple    then serialize_tuple(value, type, *args)
      when Type::Object   then serialize_object(value, type, *args)
      when Type::Union    then serialize_union(value, type, *args)
      when Type::Constructor then serialize_value(value, type, *args) # Numeric, Null, String, Boolean etc
      else raise SerializationError, "Type #{type} not supported for serialization of #{value.inspect}"
      end
    end

    def serialize_map(value, type, *)
    end

    def serialize_sequence(value, type, *)
    end

    def serialize_tuple(value, type, *)
    end

    def serialize_object(value, type, *)
    end

    def serialize_value(value, type, *)
    end

    def serialize_union(value, type, *args)
      type = type.alternative_types.find {|t| t.shallow_check_type(value)}
      raise SerializationError, "No types in union #{type} matched #{value.inspect}, could not serialize" unless type
      serialize_type(value, type, *args)
    end
  end

  class JsonableSerializer < Serializer
    def initialize(type, options={})
      super(type)
      @type_tag_key = (options[:type_tag_key] || '__class__').freeze
      @class_to_type_tag = options[:class_to_type_tag]
      @type_tag_to_class = options[:type_tag_to_class] || (@class_to_type_tag && @class_to_type_tag.invert)
      @identity_property = options[:identity_property]
      @identity_only_beyond_depth = options[:identity_only_beyond_depth]
      @elide_null_properties = options[:elide_null_properties]
      @max_depth = options.fetch(:max_depth, 15)
    end

    def class_to_type_tag(klass)
      @class_to_type_tag ? @class_to_type_tag[klass] : klass.to_s
    end

    def serialize_type(value, type, depth=0)
      raise SerializationError, "exceeded max depth of #{@max_depth}" if depth > @max_depth
      super
    end

    def serialize_slice(value, type, depth)
      slice = value[type.slice]
      result = {
        @type_tag_key => class_to_type_tag(value.class),
        'range_start' => type.slice.begin
      }
      result['items'] = slice.map {|v| serialize_type(v, type.type, depth+1)} if slice
      result['total_items'] = value.length if type.total_length
      result
    end

    def serialize_sequence(value, type, depth)
      value.map {|v| serialize_type(v, type.type, depth+1)}
    end

    def serialize_map(value, type, depth)
      raise SerializationError, "JSON only supports string keys for maps" unless Type::String === type.key_type
      result = {}
      value.each {|k,v| result[k.to_s] = serialize_type(v, type.value_type, depth+1)}
      result
    end

    def serialize_tuple(value, type, depth)
      type.types.zip(value).map {|t,v| serialize_type(v, t, depth+1)}
    end

    def serialize_object(value, type, depth)
      result = {@type_tag_key => class_to_type_tag(value.class)}
      if @identity_only_beyond_depth &&
         depth >= @identity_only_beyond_depth &&
         (id_type = type[@identity_property])

        result[@identity_property.to_s] = serialize_value(value.send(@identity_property), id_type)
      else
        result = {@type_tag_key => class_to_type_tag(value.class)}
        type.property_names_to_types.each do |prop_name, type|
          v = serialize_type(value.send(prop_name), type, depth+1)
          result[prop_name.to_s] = v unless @elide_null_properties && v.nil?
        end
      end

      result
    end

    def serialize_value(value, *)
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

  class YAMLSerializer < Serializer
    def initialize(type, options={})
      super(type)
      @yaml_domain = options[:yaml_domain]
      @class_to_type_tag = options[:class_to_type_tag]
      @type_tag_to_class = options[:type_tag_to_class] || (@class_to_type_tag && @class_to_type_tag.invert)
    end

    def serialize(value)
      super(value).to_yaml
    end

    def tagged_yaml_node_for(klass, value)
      YAML::DomainType.new(@yaml_domain,
        @class_to_type_tag ? @class_to_type_tag[klass] : klass.to_s,
        value
      )
    end

    def serialize_type(value, type, existing={})
      ex = existing[[type,value]] and return ex
      result = super(value, type, existing)
      result
    end

    def serialize_sequence(value, type, existing)
      result = existing[[type, value]] = []
      value.each {|v| result << serialize_type(v, type.type, existing)}
      result
    end

    def serialize_tuple(value, type, existing)
      result = existing[[type, value]] = []
      type.types.zip(value).each {|t,v| result << serialize_type(v,t,existing)}
      result
    end

    def serialize_object(value, type, existing)
      result = existing[[type, value]] = tagged_yaml_node_for(value.class, hash={})
      type.property_names_to_types.each do |prop_name, type|
        hash[prop_name.to_s] = serialize_type(value.send(prop_name), type, existing)
      end
      result
    end

    def serialize_map(value, type, depth)
      result = existing[[type, value]] = {}
      value.each {|k,v| result[k.to_s] = serialize_type(v, type.value_type, existing)}
      result
    end

    def serialize_slice(value, type, existing)
      slice = value[type.slice]
      result = existing[[type, value]] = tagged_yaml_node_for(value.class, hash={
        'range_start' => type.slice.begin
      })
      hash['items'] = slice.map {|v| serialize_type(v, type.type, existing)} if slice
      hash['total_items'] = value.length if type.total_length
      result
    end

    def serialize_value(value, *)
      value
    end
  end
end
