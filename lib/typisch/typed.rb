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
        @type ||= if @type_name
          @type_registry[@type_name]
        else
          raise "Forgot to register_type for Typisch::Typed class"
        end
      end

      def type_of(property_name)
        type[property_name]
      end

    protected
      attr_reader :type_name, :type_registry

    private
      def register_type(in_registry = Typisch.global_registry, register_as_symbol = to_s.to_sym, &block)
        raise "Type already registered for #{self}" if @type_name
        klass = self; type = nil
        in_registry.register do
          type = object(klass, &block)
          register(register_as_symbol, type)
        end
        @type_name = register_as_symbol
        @type_registry = in_registry
        type.property_names_to_types.map do |name, type|
          # watch out: type may be a named placeholder at this point, so
          # don't try poking at it too hard
          define_typed_attribute(name)
          alias_method(:"#{name}?", name) if Type::Boolean === type
        end
      end

      def register_subtype(in_registry = Typisch.global_registry, register_as_symbol = to_s.to_sym, &block)
        raise "Type already registered for #{self}" if @type_name
        raise "register_subtype: superclass was not typed" unless superclass < Typed
        supertype = superclass.type_registry[superclass.type_name] # avoid prematurely memoizing .type on the superclass
        klass = self; type = nil
        in_registry.register do
          type = object_subtype(supertype, klass, &block)
          register(register_as_symbol, type)
        end
        @type_name = register_as_symbol
        @type_registry = in_registry
        type.property_names_to_types.map do |name, type|
          next if supertype.property_names_to_types.has_key?(name)
          define_typed_attribute(name)
          alias_method(:"#{name}?", name) if Type::Boolean === type
        end
      end

      # override this if you want your own funky attributes instead of a vanilla attr_accessor
      # for any typed properties.
      def define_typed_attribute(name)
        attr_accessor(name) unless method_defined?(name)
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
