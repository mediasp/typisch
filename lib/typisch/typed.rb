module Typisch

  # A module which classes or modules can be extended with in order
  # to help register an object type for that class or module, associate
  # it with the class, and auto-define attributes on the class for the
  # properties of its type.
  #
  # To be used like so:
  #
  # class Foo
  #   extend Typisch::Typed
  #   register_type do
  #     property :foo, :bar
  #     ...
  #   end
  # end
  module Typed
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

#  class Typisch::Typed
end
