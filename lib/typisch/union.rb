module Typisch
  class Type::Union < Type
    attr_reader :alternative_types

    def initialize(*alternative_types)
      @alternative_types = alternative_types
    end

    def to_s
      @alternative_types.join(' | ')
    end

    # there are a lot of ways in which we can canonicalize unions, and it's
    # particularly useful to have a good canonical form for them. so this is
    # a biggie.
    def canonicalize(existing_canonicalizations={})
      result = existing_canonicalizations[self] and return result
      
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

      # find out the canonicalizations of our children:
      types = @alternative_types.map {|t| t.canonicalize(existing_canonicalizations)}

      # any of these which in turn are unions, need to get flattened out.
      # (because we recursively canonicalised them, we know that unions within
      # the children must only go one level deep - unless there was a cyclic
      # reference, which we'll deal with in a sec)
      types.map!(&:alternative_types).flatten!(1)

      if types.any? {|t| t.equal?(result)}
        raise "Disallowed recursive reference to union without a type constructor inbetween"
      end

      # now group by tagged type, and ask the relevant tagged type subclasses
      # to canonicalize_union
      types = types.group_by(&:class).map do |klass, types|
        klass.canonicalize_union(*types)
      end.flatten(1)

      result.send(:initialize, *types)
    end
    
  end

  # The Nothing (or 'bottom') type is just an empty Union:
  class Type::Nothing < Type::Union
    def initialize
      super
    end

    def to_s
      "Nothing"
    end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:nothing, INSTANCE)
  end

  # The Any (or 'top') type is just a union of all the top types of the various Type::Tagged
  # subclasses:
  class Type::Any < Type::Union
    def initialize
      super(*Tagged::TAGGED_TYPE_SUBCLASSES.map {|klass| klass.top_type(self)})
    end

    def to_s
      "Any"
    end

    INSTANCE = new
    class << self; private :new; end
    Registry.register_global_type(:any, INSTANCE)
  end
end
