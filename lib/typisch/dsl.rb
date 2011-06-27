module Typisch
  module DSL
    def registry
      raise NotImplementedError
    end

    def register(name, *type_args, &type_block_arg)
      registry[name] = type(*type_args, &type_block_arg)
    end

    def type(arg, *more_args, &block_arg)
      case arg
      when Type
        arg
      when ::Symbol
        if more_args.empty? && !block_arg
          registry[arg]
        else
          send(arg, *more_args, &block_arg)
        end
      else
        raise ArgumentError, "expected Type or type name, but was given #{arg.class}"
      end
    end

    def sequence(type_arg)
      Type::Sequence.new(type(type_arg))
    end

    def tuple(*types)
      Type::Tuple.new(*types.map {|t| type(t)})
    end

    def object(klass_or_properties=nil, properties=nil, &block)
      klass, properties = case klass_or_properties
      when ::Hash, ::NilClass then [::Object, klass_or_properties]
      when ::Module then [klass_or_properties, properties]
      end
      properties ||= {}
      properties.merge!(ObjectContext.capture(self, &block)) if block
      properties.keys.each do |k|
        type_args, type_block_arg = properties[k]
        properties[k] = type(*type_args, &type_block_arg)
      end
      Type::Object.new(klass.to_s, properties)
    end

    def object_subtype(supertype, klass=nil, properties={}, &block)
      supertype = type(supertype)
      klass ||= supertype.class_or_module
      properties = supertype.property_names_to_types.merge(properties)
      object(klass, properties, &block)
    end

    def union(*types)
      Type::Union.new(*types.map {|t| type(t)})
    end

    class ObjectContext
      attr_reader :properties

      def self.capture(parent_context, &block)
        x = new(parent_context)
        x.instance_eval(&block)
        x.properties
      end

      def initialize(parent_context)
        @parent_context = parent_context
        @properties = {}
      end

      def property(name, *type_args, &type_block_arg)
        raise Error, "property #{name.inspect} declared twice" if @properties[name]
        @properties[name] = [type_args, type_block_arg]
      end

      def method_missing(name, *args, &block)
        @parent_context.respond_to?(name) ? @parent_context.send(name, *args, &block) : super
      end
    end
  end

  class DSLContext
    include DSL

    attr_reader :registry

    def initialize(registry)
      @registry = registry
    end
  end

end
