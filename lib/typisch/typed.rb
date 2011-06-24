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
      if full_check
        type === send(name)
      else
        type.shallow_check_type(send(name))
      end or raise TypeError, "property #{name} was expected to be of type #{type}"
    end

    module ClassMethods
      def type
        @type or raise "Forgot to register_type for Typisch::Typed class"
      end

      def type_of(property_name)
        @type[property_name]
      end

    private
      def register_type(in_registry = Typisch.global_registry, register_as_symbol = to_s.to_sym, &block)
        raise "Type already registered for #{self}" if @type
        klass = self; type = nil
        in_registry.register do
          type = object(klass, &block)
          register(register_as_symbol, type)
        end
        @type = type
        @type.property_names_to_types.map do |name, type|
          # watch out: type may be a named placeholder at this point, so
          # don't try poking at it too hard
          define_typed_attribute(name)
          alias_method(:"#{name}?", name) if Type::Boolean === type
        end
      end

      # override this if you want your own funky attributes instead of a vanilla attr_accessor
      # for any typed properties.
      def define_typed_attribute(name)
        attr_accessor(name)
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
