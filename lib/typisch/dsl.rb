module Typisch
  module DSL
    def registry
      raise NotImplementedError
    end

    def register(name, *type_args, &type_block_arg)
      result = registry[name] = type(*type_args, &type_block_arg)
      if @pending_annotations
        result.annotations.merge!(@pending_annotations)
        @pending_annotations = nil
      end
      result
    end

    # annotations apply to the next register'd type.
    #
    # annotate "Some description", :some_other => 'annotations'
    # annotate :description => "Some description", :some_other => 'annotations'
    def annotate(description_or_options, options=nil)
      if description_or_options.is_a?(::String)
        options ||= {}; options[:description] = description_or_options
      else
        options = description_or_options
      end
      @pending_annotations ||= {}
      @pending_annotations.merge!(options)
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
      if block
        object_context = ObjectContext.new(self)
        object_context.instance_eval(&block)
        properties.merge!(object_context.properties)
      end
      properties.keys.each do |k|
        type_args, type_block_arg = properties[k]
        properties[k] = type(*type_args, &type_block_arg)
      end
      type = Type::Object.new(klass.to_s, properties)
      if block && (prop_annot = object_context.property_annotations)
        type.annotations[:properties] = prop_annot
      end
      type
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

    def nullable(t)
      union(type(t), :null)
    end

    class ObjectContext
      attr_reader :properties, :property_annotations

      def initialize(parent_context)
        @parent_context = parent_context
        @properties = {}
      end

      # property annotations apply to the next declared property.
      #
      # annotate "Some description", :some_other => 'annotations'
      # annotate :description => "Some description", :some_other => 'annotations'
      def annotate(description_or_options, options=nil)
        if description_or_options.is_a?(::String)
          options ||= {}; options[:description] = description_or_options
        else
          options = description_or_options
        end
        @pending_annotations ||= {}
        @pending_annotations.merge!(options)
      end

      def property(name, *type_args, &type_block_arg)
        raise Error, "property #{name.inspect} declared twice" if @properties[name]
        @properties[name] = [type_args, type_block_arg]
        if @pending_annotations
          @property_annotations ||= {}
          @property_annotations[name] = @pending_annotations
          @pending_annotations = nil
        end
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
