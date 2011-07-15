module Typisch
  Type::LATTICES = []

  # All types except Top, Bottom and Unions (which may necessarily involve more than one constructor type) have a
  # tag associated with them which is used at runtime to distinguish its instances somewhat from instances
  # of other types.
  #
  # This is an abstract superclass; each subclass of Type::Constructor is assumed to implement its own, distinct
  # lattice of types. For simple atomic types like Bool, there will only be one tag, "Bool", in that lattice.
  #
  # While the type lattices of different subclass of Type::Constructor are non-overlapping, within a subclass
  # (such as Type::Object or Type::Numeric) there may be a non-trivial type lattice, eg for Numeric,
  # Int < Float, and for Object, the type lattice is based on a nominal tag inheritance hierarchy in
  # the host language together with structural subtyping rules for object properties.
  class Type::Constructor < Type
    class << self
      # This should be the top in the type lattice for this class of taged types.
      # Its tag should be the top_tag above.
      # You are passed the overall_top, ie the top type of the overall type lattice,
      # to use; this is needed by parameterised types which want to parameterise their
      # top type by the overall top, eg Top = Foo | Bar | Sequence[Top] | ...
      def top_type(overall_top)
        raise NotImplementedError
      end

      # This gets called by the subtyper on a Type::Constructor subclass, with two instances of
      # that subclass.
      # It should return true or false; if it needs to check some subgoals,
      # say on child types of the ones passed in, it should use the supplied
      # 'recursively_check_subtype' block rather than calling itself recursively
      # directly. This hides away the details of the corecursive subtyping algorithm
      # for you.
      def check_subtype(x, y, &recursively_check_subtype)
        raise NotImplementedError
      end
    end

    # the distinct type lattice within which this type lives.
    # the type system as a whole can be seen as a set of non-overlapping type lattices, together
    # with tagged unions drawn from them.
    #
    # the interface for a type lattice is just that it responds to 'check_subtype'; by default
    # the class of a type implements this interface
    def type_lattice
      self.class
    end

    def check_type(instance)
      shallow_check_type(instance)
    end

    # the tag of this particular type
    def tag
      raise NotImplementedError
    end

    # these are here so as to implement a common interface with Type::Union
    def alternative_types
      [self]
    end

    # A class of constructor type of which there is only one type, and
    # hence only one tag.
    #
    # Will have no supertype besides Any, and no subtype besides
    # Nothing.
    #
    # (abstract superclass; see Boolean or Null for example subclasses).
    class Singleton < Type::Constructor
      class << self
        private :new

        def tag
          raise NotImplementedError
        end

        def top_type(*)
          @top_type ||= new
        end

        def check_subtype(x, y)
          true
        end
      end

      def subexpression_types
        []
      end

      def tag
        self.class.tag
      end

      def to_s(*)
        @name.inspect
      end
    end
  end
end
