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
  class Type::Tagged < self
    RESERVED_TAGS = []
    TAGGED_TYPE_SUBCLASSES = []

    class << self
      def inherited(subclass)
        TAGGED_TYPE_SUBCLASSES << subclass
        super
      end
      
      # Class methods implementing a tag lattice for each subclass of Type::Tagged.        
      # Defaults to a trivial lattice consisting of just a single tag.
    
      def subtag?(x, y)
        x == y
      end

      # Type::Tagged subclasses must supply a tag which applies to all their instances.
      # For something like Type::Object which allows for a whole lattice of tags, this would
      # be the top element of that lattice.
      def top_tag
        raise NotImplementedError
      end
    
      # lub of two tags, defaults to the top tag
      def least_upper_bound_tag(x, y)
        top_tag
      end

      # Two tags are not required to have a greatest lower bound, and in particular there's not
      # necessarily a 'bottom' tag. If two tags lack a lower bound, they are non-overlapping,
      # which is important when the tags are to be used to distinguish types in a tagged union.
      #
      # (note there is an overall bottom *type*, but it's obviously uninhabited, so no runtime
      #  tag needs to be available to be associated with its instances).
      def greatest_lower_bound_tag(x, y)
        x if x == y
      end
    
      def tags_overlap?(x, y)
        !greatest_lower_bound_tag(x, y).nil?
      end

      # This should be the top in the type lattice for this class of taged types.
      # Its tag should be the top_tag above.
      # You are passed the overall_top, ie the top type of the overall type lattice,
      # to use; this is needed by parameterised types which want to parameterise their
      # top type by the overall top, eg Top = Foo | Bar | Sequence[Top] | ...
      def top_type(overall_top)
        new(top_tag)
      end
      
      # This gets called by the subtyper on a Type::Tagged subclass, with two instances of
      # that subclass.
      # By default we just check the subtag? relationship holds on their tags, but subclasses
      # may want to override to return extra subgoals.
      def subgoals_to_prove_subtype(x, y)
        subtag?(x.tag, y.tag) && []
      end
    end

    def initialize(*); end
  
    # the tag of this particular type. default implementation assumes the top_tag is the only
    # tag used for the class.
    def tag
      self.class.top_tag
    end
    
    # these are here so to implement a common interface with Type::Union
    def alternative_tagged_types
      [self]
    end

    def alternative_types_by_tag
      {tag => self}
    end
  end
end