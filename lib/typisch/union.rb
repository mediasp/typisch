module Typisch
  class Type::Union < Type
    attr_reader :alternative_types
    alias :subexpression_types :alternative_types

    def initialize(*alternative_types)
      @alternative_types = alternative_types
    end

    def check_type(instance, &recursively_check_type)
      # this relies on the safe backtracking provided by the recursively_check_type
      # block passed in by the caller
      @alternative_types.any? {|t| recursively_check_type[t, instance]}
    end

    def shallow_check_type(instance)
      @alternative_types.any? {|t| t.shallow_check_type(instance)}
    end

    # Aside from sorting out uses of recursion, canonicalising unions is
    # the main non-trivial thing which canonicalisation does to the type
    # graph at present.
    def canonicalize(existing_canonicalizations={}, recursion_unsafe={})
      raise IllFormedRecursiveType if recursion_unsafe[self]
      result = existing_canonicalizations[self] and return result
      recursion_unsafe[self] = true

      if @alternative_types.length == 0
        # Return the special 'Nothing' type as the canonicaliszation of an
        # empty union. (Nothing is just an empty union itself, but one with
        # a special printed name; so this is superficial but nice to do)
        existing_canonicalizations[self] = Type::Nothing::INSTANCE
        return Type::Nothing::INSTANCE
      end

      # pre-allocate a placeholder for our result, which we pass on to child
      # nodes
      result = existing_canonicalizations[self] = Type::Union.allocate

      # find out the canonicalizations of our children.
      # we pass on the set of recursion_unsafe things when doing so, because a union isn't a constructor
      # type and we need to encounter a constructor type before we can allow recursion
      types = @alternative_types.map {|t| t.canonicalize(existing_canonicalizations, recursion_unsafe)}

      # pop ourselves off the recursion_unsafe 'stack' now we're done calling canonicalize
      # recursively
      recursion_unsafe.delete(self)

      # Now, any of these which in turn are unions, need to get flattened out.
      # Because we recursively canonicalised them, we know that unions within
      # the children must only go one level deep.
      # Unless, there was a cyclic reference back to us within one of the nested unions,
      # which we'll need to catch afterwards.
      types.map!(&:alternative_types).flatten!(1)

      # now, we see what's the smallest subset of these types whose union is equal to that
      # of the overall set?
      types = Typisch.find_minimal_set_of_upper_bounds(*types)

      # finally can initialize the union which we allocated earlier:
      result.send(:initialize, *types)

      # hang on though - if there's only one term in the union, we'd actually rather
      # canonicalise to that one term, without a redundant union wrapper around it.
      #
      # Note that the pre-allocated Union object still got passed recursively to
      # children, so we do initialize it so any children who picked up on it can
      # use it without breaking (they just won't get the benefit of this additional
      # optimisation). This is unlikely to happen though.
      if types.length == 1
        result = existing_canonicalizations[self] = types.first
      end

      result
    end

    def to_string(depth, indent)
      next_indent = "#{indent}  "
      types = @alternative_types.map {|t| t.to_s(depth+1, next_indent)}
      "union(\n#{next_indent}#{types.join(",\n#{next_indent}")}\n#{indent})"
    end

  end

  # The Nothing (or 'bottom') type is just an empty Union:
  class Type::Nothing < Type::Union
    def initialize
      super
    end

    def to_s(*); @name.inspect; end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:nothing, INSTANCE)
  end

  # The Any (or 'top') type is just a union of all the top types of the various Type::Constructor
  # subclasses:
  class Type::Any < Type::Union
    def initialize
      super(*Constructor::CONSTRUCTOR_TYPE_SUBCLASSES.map {|klass| klass.top_type(self)})
    end

    def to_s(*); @name.inspect; end

    # skip some unnecessary work checking different alternatives, since we know everything
    # works here:
    def check_type(instance)
      true
    end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:any, INSTANCE)
  end
end
