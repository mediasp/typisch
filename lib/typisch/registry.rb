module Typisch
  # A registry is a glorified hash lookup of types by name
  #
  # - provide a concise way of referring to more complex types
  # - help with the wiring up of recursive types
  # -
  #
  class Registry
    attr_reader :types_by_name

    def initialize
      @types_by_name = GLOBALS.dup
    end

    def [](name)
      @types_by_name[name] ||= Type::NamedPlaceholder.new(name, self)
    end

    def []=(name, type)
      case @types_by_name[name]
      when Type::NamedPlaceholder
        @types_by_name[name].send(:target=, type)
        @types_by_name[name] = type
      when NilClass
        @types_by_name[name] = type
      else
        raise "type already registered with name #{name.inspect}"
      end
      define_instance_method(name) {type} if ::Symbol === name
    end

    def define_instance_method(name, &block)
      (class << self; self; end).send(:define_method, name, &block)
    end

    # While loading, we'll register various types in this hash of types
    # (boolean, string, ...) which we want to be included in all registries
    GLOBALS = {}
    def self.register_global_type(name, type)
      GLOBALS[name] = type
      define_method(name) {type}
    end

    def register(&block)
      DSLContext.new(self).instance_eval(&block)
    end
  end

  # This is a proxy wrapper for a type, which we can use as a placeholder for a named
  # type which hasn't yet been declared. Helps when it comes to cyclic references etc/
  class Type::NamedPlaceholder < Type
    def initialize(name, registry)
      @registry = registry
      @name = name
    end

    def target
      return @target if @target
      @target = @registry[@name]
      case @target when NilClass, Type::NamedPlaceholder
        raise "Problem resolving named placeholder type: cannot find type with name #{@name.inspect} in registry"
      end
    end

    attr_writer :target
    private :target=

    # this is slightly naughty - we actually pretend to be of the class
    # of our target object.
    #
    # note that TargetClass === placeholder will still return false.

    def class
      target.class
    end

    def is_a?(klass)
      target.is_a?(klass)
    end
    alias :kind_of? :is_a?

    def instance_of?(klass)
      target.instance_of?(klass)
    end

    def to_s
      @name.inspect
    end

    undef :alternative_types # let us proxy this through

    def method_missing(name, *args, &block)
      target.respond_to?(name) ? target.send(name, *args, &block) : super
    end

    def respond_to?(name, include_private=false)
      super || target.respond_to?(name, include_private)
    end
  end

  # We set up a global registry which you can use if you like, either
  # via Typisch.global_registry or via the convenience aliases
  # Typisch.[] and Typisch.register.
  #
  # Or, you can make your own registry if you don't want to share a
  # global registry with other code using this library. (recommended
  # if writing modular code / library code which uses this).

  def self.global_registry
    @global_registry ||= Registry.new
  end

  def self.register(&block)
    global_registry.register(&block)
  end

  def self.[](name)
    global_registry[name]
  end

end
