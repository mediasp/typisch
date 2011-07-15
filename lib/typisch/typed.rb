module Typisch

  # A module which classes or modules can be extended with in order
  # to help register an object type for that class or module, associate
  # it with the class, and auto-define attributes on the class for the
  # properties of its type.
  #
  # To be used like so:
  #
  # class Foo
  #   include Typisch::Typed
  #   register_type do
  #     property :foo, :bar
  #     ...
  #   end
  # end
  module Typed
    def self.included(klass)
      super
      klass.send(:extend, ClassMethods)
    end

    def type
      self.class.type
    end

    def type_check(full_check=false)
      if full_check
        self.class.type === self or raise TypeError, "failed to type-check"
      else
        self.class.type.property_names.each {|a| type_check_property(a, false)}
      end
    end

    def type_check_property(name, full_check=false)
      type = self.class.type_of(name) or raise NameError, "no typed property #{name} in #{self.class}"
      value = send(name)
      if full_check
        type === send(value)
      else
        type.shallow_check_type(value)
      end or raise TypeError, "property #{name} was expected to be of type #{type}, got instance of #{value.class}"
    end

    module ClassMethods
      def type
        @type || raise("Forgot to register_type for Typisch::Typed class")
      end

      def type_of(property_name)
        type[property_name]
      end

      def version_types
        @version_types ||= {}
      end

      def versions
        version_types.keys
      end

      def version_type(key)
        version_types[key]
      end

    private
      def register_type(in_registry = Typisch.global_registry, derive_from_type=nil, &block)
        raise "Type already registered for #{self}" if @type

        # a pox on instance_eval's scoping rules :(
        callback = method(:type_available); klass = self; type = nil
        in_registry.register do
          type = _object(klass, {}, derive_from_type, &block)
          klass.send(:instance_variable_set, :@type, type)
          in_registry.register_type_for_class(type, &callback)
        end
        type
      end

      def register_version_type(version, in_registry = Typisch.global_registry, &block)
        raise "should register_type before register_version_type" unless @type

        callback = method(:type_available); klass = self; type = nil
        derive_from_type = @type
        in_registry.register do
          type = _object(klass, {}, derive_from_type, &block)
          klass.version_types[version] = type
          in_registry.register_type_for_class(type, version, &callback)
        end
        type
      end

      # Called once the type which you registered is available in a fully canonicalized form
      # (so eg any forward declarations to types defined in other still-to-be-required classes,
      # will have been resolved at this point).
      #
      # By default declares an attr_accessor for each property, and aliases it with a ? on the
      # end if it's a boolean property. Override if you want to do something different.
      def type_available
        type.property_names_to_types.map do |name, type|
          attr_accessor(name) unless method_defined?(name)
          alias_method(:"#{name}?", name) if type.excluding_null.is_a?(Type::Boolean)
        end
      end

      def register_subtype(in_registry = Typisch.global_registry, &block)
        raise "Type already registered for #{self}" if @type
        raise "register_subtype: superclass was not typed" unless superclass < Typed
        supertype = superclass.send(:type)
        callback = method(:type_available); klass = self; type = nil
        in_registry.register do
          type = derived_from(supertype, klass) do
            instance_eval(&block)
            derive_all_properties
          end
          klass.send(:instance_variable_set, :@type, type)
          in_registry.register_type_for_class(type, &callback)
        end
      end
    end
  end

  class Typisch::TypedStruct
    include Typisch::Typed

    def initialize(properties={})
      properties.each {|p,v| instance_variable_set("@#{p}", v)}
    end
  end
end
