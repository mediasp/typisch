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

    def register_type(name, type, &callback_on_canonicalization)
      case @types_by_name[name]
      when Type::NamedPlaceholder
        @types_by_name[name].send(:target=, type)
      when NilClass
      else
        raise Error, "type already registered with name #{name.inspect}"
      end
      type.send(:name=, name) unless type.name
      @types_by_name[name] = type
      @pending_canonicalization[name] = [type, callback_on_canonicalization]
    end
    alias :[]= :register_type

    # While loading, we'll register various types in this hash of types
    # (boolean, string, ...) which we want to be included in all registries
    GLOBALS = {}
    def self.register_global_type(name, type)
      type.send(:name=, name) unless type.name
      GLOBALS[name] = type
    end

    # All registering of types in a registry needs to be done inside one of these
    # blocks; it ensures that the any forward references or cyclic references are
    # resolved (via canonicalize!-ing every type in the type graph) once you've
    # finished registering types.
    #
    # This also ensures that any uses of recursion are valid / well-founded, and
    # does any other necessary validation of the type graph you've declared which
    # isn't possible to do upfront.
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

      types = @pending_canonicalization.values.map {|t,c| t}
      each_type_in_graph(*types) {|t| t.canonicalize!}
      @pending_canonicalization.each {|name,(type,callback)| callback.call if callback}
      @pending_canonicalization = {}
    end

    def each_type_in_graph(*types)
      seen_so_far = {}
      while (type = types.pop)
        next if seen_so_far[type]
        seen_so_far[type] = true
        yield type
        types.push(*type.subexpression_types)
      end
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
