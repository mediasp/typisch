module Typisch
  # All types except Top, Bottom and Unions (which may necessarily involve more than one tagged type) have a
  # tag associated with them which is used at runtime to distinguish its instances somewhat from instances
  # of other types.
  #
  # This is an abstract superclass; each subclass of Type::Tagged is assumed to implement its own, distinct
  # lattice of tags. For simple atomic types like Bool, there will only be one tag, "Bool", in that lattice.
  #
  # While tags are assumed to be non-overlapping between different subclass of Type::Tagged, within a subclass
  # (such as Type::Object or Type::Numeric) there may be a non-trivial tag lattice, eg for Numeric,
  # Int < Float, and for Object, the tag lattice may be based on a nominal subtyping inheritance hierarchy in
  # the host language.
  #
  # A list of 'reserved tags' is maintained globally, and any Type::Tagged subtype which allows custom
  # user-specified tags to be used should ensure that they don't match any reserved tags.
  class Type::Tagged < Type
    RESERVED_TAGS = []
    TAGGED_TYPE_SUBCLASSES = []

    class << self
      def inherited(subclass)
        # we add any non-abstract subclasses to this list, which is used to
        # construct the Any type. For now Tagged::Singleton is the only
        # other abstract Type::Tagged subclass:
        unless subclass == Type::Tagged::Singleton
          TAGGED_TYPE_SUBCLASSES << subclass
        end
        super
      end

      # This should be the top in the type lattice for this class of taged types.
      # Its tag should be the top_tag above.
      # You are passed the overall_top, ie the top type of the overall type lattice,
      # to use; this is needed by parameterised types which want to parameterise their
      # top type by the overall top, eg Top = Foo | Bar | Sequence[Top] | ...
      def top_type(overall_top)
        raise NotImplementedError
      end

      # This gets called by the subtyper on a Type::Tagged subclass, with two instances of
      # that subclass.
      # By default we just check their tags are the same, but subclasses
      # may want to override to return extra subgoals.
      def check_subtype(x, y)
        x.tag == y.tag
      end

      # Where there are a number of alternatives in a Union type of this class,
      # of which the given type x (also of this class) might be a subtype, we are
      # asked to pick one.
      #
      # If we can find one y which x *might* be a subtype of, we return the pair
      # [x, y] as a goal for further testing.
      #
      # If there are no ys which have a chance of x being a subtype of them, we
      # return nil.
      #
      # We should be prepared to be able to make only one unique choice from the
      # alternatives, discarding the other alternatives; to help us do this,
      # we can implement 'least_upper_bounds_for_union' to consolidate together
      # types of our class which are being unioned. The list of alternatives
      # we get here will then always be one of these consolidated lists, a
      # tagged union effectively.
      # (Often the list will only have one member, which is what the default
      #  implementation assumes)
      def pick_subtype_goal_from_alternatives_in_union(x, alternative_ys)
        raise "unexpected multiple alternatives of class #{self} in union" if alternative_ys.length > 1
        y = alternative_ys.first and [x, y]
      end

      # If you support 'tagged' unions, you should group the types by
      # tag, and then return, for each tag, the respective least upper
      # bound of all types in the list with that tag.
      #
      # The thing to bear in mind with tagged unions is that you'll be
      # called upon to pick one unique choice from the clauses of a tagged
      # union, for testing as a possible supertype of some given type.
      # So the clauses of your tagged union must be non-overlapping, both
      # in the subtype lattice and in terms of being able to differentiate
      # instances when type-checking at runtime.
      #
      # If you don't support tagged unions, this reduces to just returning
      # a single least upper bound of all the given types.
      def least_upper_bounds_for_union(*types)
        # we can't just use 'uniq' as this is based on hash/eql?, and we want based on ==.
        result = []
        types.uniq.each {|t| result << t unless result.include?(t)}
        result
      end
    end

    def initialize(*); end

    # the tag of this particular type
    def tag
      raise NotImplementedError
    end

    def to_s
      tag
    end

    # these are here so to implement a common interface with Type::Union
    def alternative_types
      [self]
    end

    def alternative_types_by_class
      {self.class => [self]}
    end

    # A class of tagged type of which there is only one type, and
    # hence only one tag.
    #
    # Will have no supertype besides Any, and no subtype besides
    # Nothing.
    #
    # (abstract superclass; see Boolean or Null for example subclasses).
    class Singleton < Type::Tagged
      class << self
        private :new

        def tag
          raise NotImplementedError
        end

        def top_type(*)
          @top_type ||= new
        end
      end

      def tag
        self.class.tag
      end
    end
  end
end
