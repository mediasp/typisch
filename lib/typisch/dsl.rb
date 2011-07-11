module Typisch

  # Apologies this is a bit messy. Should probably do a bit of a tidy-up
  # once the dust has settled around the DSL syntax.
  #
  # It's a layer ontop of the core type model though - could be worse, it
  # could be horribly intertwined with the model itself :)

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

    def register_type_for_class(klass, *object_type_args, &object_type_block_arg)
      name = :"#{klass}"
      type = register(name, :object, klass, *object_type_args, &object_type_block_arg)
      registry.register_type_for_class(klass, type)
      type
    end

    def register_version_type_for_class(klass, version, *object_type_args, &object_type_block_arg)
      name = :"#{klass}__#{version}"
      type = register(name, :object, klass, *object_type_args, &object_type_block_arg)
      registry.register_version_type_for_class(klass, version, type)
      type
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
        elsif more_args.last.is_a?(::Hash) && !block_arg && (version = more_args.last[:version])
          registry[:"#{arg}__#{version}"]
        else
          send(arg, *more_args, &block_arg)
        end
      when ::Module
        type(:"#{arg}", *more_args, &block_arg)
      else
        raise ArgumentError, "expected Type or type name or class, but was given #{arg.class}"
      end
    end

    def sequence(*type_args)
      Type::Sequence.new(type(*type_args))
    end

    def tuple(*types)
      Type::Tuple.new(*types.map {|t| type(t)})
    end

    def object(*args, &block)
      klass, properties = _normalize_object_args(::Object, *args)
      _object(klass, properties, &block)
    end

    def _normalize_object_args(default_class, klass_or_properties=nil, properties=nil)
      case klass_or_properties
      when ::Hash     then [default_class, klass_or_properties]
      when ::NilClass then [default_class, {}]
      when ::Module   then [klass_or_properties, properties || {}]
      end
    end

    # back-end for object, which takes args in a normalized format
    def _object(klass, properties, derive_from=nil, &block)
      if block
        object_context = if derive_from
          DerivedObjectContext.new(self, derive_from)
        else
          ObjectContext.new(self)
        end
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

    def union(*types)
      Type::Union.new(*types.map {|t| type(t)})
    end

    def nullable(t)
      union(type(t), :null)
    end

    def derived_from(original_type, *args, &block_arg)
      if args.empty? && !block_arg
        original_type
      elsif args.last.is_a?(::Hash) && (version = args.last[:version]) && original_type.name
        # slightly messy; we rely on the convention that 'versions' of named types are registered
        # as :"#{name}__#{version}", this allows you to specify or override the version when
        # deriving from a type, even if it is still just a named placeholder, by manipulating the
        # name.
        original_name = original_type.name.to_s.sub(/__.*$/, '')
        :"#{original_name}__#{version}"
      else
        original_type = type(original_type).target
        case original_type
        when Type::Object
          klass, properties = _normalize_object_args(original_type.class_or_module, *args)
          _object(klass, properties, original_type, &block_arg)
        when Type::Sequence
          Type::Sequence.new(derived_from(original_type.type, *args, &block_arg))
        when Type::Union
          non_null = original_type.excluding_null
          raise "DSL doesn't support deriving from union types (except simple unions with null)" if Type::Union === non_null
          nullable(derived_from(non_null, *args, &block_arg))
        else
          raise "DSL doesn't support deriving from #{original_type.class} types" if args.length > 0 || block_arg
          original_type
        end
      end
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

    class DerivedObjectContext < ObjectContext
      def initialize(c, original_object_type)
        super(c)
        @original_object_type = original_object_type
      end

      def derive_properties(*names)
        names.each {|n| derive_property(n)}
      end

      # use a property from the original object type being derived from
      def derive_property(name, *derive_args, &derive_block)
        type = @original_object_type[name] or raise "use_property: no such property #{name.inspect} on the original type"
        derived_type = derived_from(type, *derive_args, &derive_block)
        property name, derived_type
      end

      # derives all properties from the original type which haven't already been derived.
      # this is done for you by Typisch::Typed::ClassMethods#register_subtype.
      def derive_all_properties
        @original_object_type.property_names_to_types.each do |name, type|
          property(name, type) unless @properties[name]
        end
      end

      def derive_all_properties_except(*props)
        @original_object_type.property_names_to_types.each do |name, type|
          next if props.include?(name)
          property(name, type) unless @properties[name]
        end
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
