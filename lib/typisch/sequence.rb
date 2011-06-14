class Typisch::Type
  class Sequence < Tagged
    class << self
      def top_type(overall_top)
        new(overall_top)
      end

      def check_subtype(x, y, &recursively_check_subtype)
        recursively_check_subtype[x.type, y.type]
      end

      # note: this kind of l.u.b. is bigger than it could be;
      # a distinction is lost, in the sense that
      # [Int] union [Bool] is a strict subset of [Int union Bool],
      # with [1, true, 2, false] in the latter but not the former.
      #
      # We *could* choose to hang on to this distinction as a union
      # of separate sequence types, but it'd mean we don't get to simplify
      # our unions as much. For now taking the road of simplifying the
      # union and pushing it down beneath Sequence, since it's quite rare
      # in practice to have a data type that's eg "sequence of ints OR
      # sequence of bools, but don't mix the two"
      def least_upper_bounds_for_union(*sequence_types)
        [new(Type::Union.union(*sequence_types.map(&:type)))]
      end
    end

    def initialize(type)
      @type = type
    end

    def tag
      "Sequence"
    end
    Tagged::RESERVED_TAGS << "Sequence"

    attr_reader :type

    def to_s
      "[#{@type}]"
    end
  end
end
