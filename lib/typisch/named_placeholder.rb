module Typisch
  # This is a proxy wrapper for a type, which we can use as a placeholder for a named
  # type which hasn't yet been declared. Helps when it comes to cyclic references etc.
  #
  # (You can view this as a free variable, where the scope of all free variables is
  #  implicitly closed over at the top level by the 'registry'. We don't keep variables
  #  lying around as symbolic things in a syntax tree though, we're just using them as
  #  temporary placeholders on the way to rewriting it as a syntax *graph*).
  #
  # Once a register_types block has finished, the registry ensures that all references
  # in the type graph to NamedPlaceholders are replaced with references to their targets.
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

    def target=(target)
      @target = target.target
    end
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

    # let us proxy these through
    undef :alternative_types, :check_type, :shallow_check_type, :subexpression_types
    undef :excluding_null, :annotations, :canonicalize!

    def method_missing(name, *args, &block)
      target.respond_to?(name) ? target.send(name, *args, &block) : super
    end

    def respond_to?(name, include_private=false)
      super || target.respond_to?(name, include_private)
    end
  end
end
