module Typisch
  # A registry is a glorified hash lookup of types by name
  #
  # - provide a concise way of referring to more complex types
  # - help with the wiring up of recursive types
  # -
  #
  class Registry
    attr_reader :types_by_name

    def initialize(&block)
      @types_by_name = GLOBALS.dup
      @pending_canonicalization = {}
      register(&block) if block
    end

    def [](name)
      @types_by_name[name] ||= Type::NamedPlaceholder.new(name, self)
    end

    def []=(name, type)
      case @types_by_name[name]
      when Type::NamedPlaceholder
        @types_by_name[name].send(:target=, type)
      when NilClass
      else
        raise Error, "type already registered with name #{name.inspect}"
      end
      type.send(:name=, name) unless type.name
      @types_by_name[name] = type
      @pending_canonicalization[name] = type
    end

    # While loading, we'll register various types in this hash of types
    # (boolean, string, ...) which we want to be included in all registries
    GLOBALS = {}
    def self.register_global_type(name, type)
      type.send(:name=, name) unless type.name
      GLOBALS[name] = type
    end

    # All registering of types in a registry needs to be done inside one of these
    # blocks; it ensures that the types are canonicalized, and any uses of recursion
    # are validated and wired up canonically afterwards.
    # If you really can't use the block, you can call canonicalize_registered_types!
    # manually once you're done registering them.
    #
    # You can nest register blocks without ill-effect; it will only try to
    # resolve forward references etc once the outermost block has exited.
    #
    # Note, this is all very much non-threadsafe, wouldn't be hard to make it so
    # (probably just slap a big mutex around it) but not sure why exactly you'd
    # want multi-threaded type registration anyway to anyway so leaving as-is for now.
    def register(&block)
      if @registering_types
        DSLContext.new(self).instance_eval(&block)
      else
        start_registering_types!
        DSLContext.new(self).instance_eval(&block)
        stop_registering_types!
      end
    end

    def start_registering_types!
      @registering_types = true
    end

    def stop_registering_types!
      @registering_types = false

      # important that we maintain the canonicalizations hash
      # between calls, so that the different registered types know
      # about how eachother canonicalize and don't duplicate work.
      canonicalizations = {}
      @pending_canonicalization.each do |name, type|
        type = @types_by_name[name] = type.canonicalize(canonicalizations)
        type.send(:name=, name) unless type.name
      end
      @pending_canonicalization = {}
    end

    # Allow you to dup and merge registries

    def initialize_copy(other)
      @types_by_name = @types_by_name.dup
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      @types_by_name.merge!(other.types_by_name)
    end

    def to_s
      pairs = @types_by_name.map do |n,t|
        next if GLOBALS[n]
        "r.register #{n.inspect}, #{t.to_s(0, '  ')}"
      end.compact
      "Typisch::Registry.new do |r|\n  #{pairs.join("\n  ")}\nend"
    end
  end

  # This is a proxy wrapper for a type, which we can use as a placeholder for a named
  # type which hasn't yet been declared. Helps when it comes to cyclic references etc.
  #
  # (You can view this as a free variable, where the scope of all free variables is
  #  implicitly closed over at the top level by the 'registry'. We don't keep variables
  #  lying around as symbolic things in a syntax tree though, we're just using them as
  #  temporary placeholders on the way to rewriting it as a syntax *graph*).
  class Type::NamedPlaceholder < Type
    def initialize(name, registry)
      @registry = registry
      @name = name
    end

    def target
      return @target if @target
      @target = @registry[@name]
      case @target when NilClass, Type::NamedPlaceholder
        raise NameResolutionError.new(@name.inspect)
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

    def to_s(*)
      @name.inspect
    end

    # canonicalizes to the canonicalisation of its target, meaning these placeholder
    # wrappers will get eliminated at the canonicalization stage.
    def canonicalize(existing_canonicalizations={}, recursion_unsafe={})
      result = existing_canonicalizations[self] and return result

      raise IllFormedRecursiveType if recursion_unsafe[self]
      recursion_unsafe[self] = true

      result = target.canonicalize(existing_canonicalizations, recursion_unsafe)
      existing_canonicalizations[self] = result

      recursion_unsafe.delete(self)

      result
    end

    # let us proxy these through
    undef :alternative_types, :check_type, :shallow_check_type, :subexpression_types
    undef :excluding_null

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
