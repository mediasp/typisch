class Typisch::Type
  class Sequence < Constructor
    class << self
      def top_type(overall_top)
        new(overall_top)
      end

      def check_subtype(x, y, &recursively_check_subtype)
        recursively_check_subtype[x.type, y.type]
      end
    end

    def initialize(type)
      @type = type
    end

    def subexpression_types
      [@type]
    end

    # We're quite liberal in allowing any Enumerable here.
    #
    # Maybe we should be slightly more strict, or have a list of
    # VALID_IMPLEMENTATION_CLASSES like some of the other types, which
    # you have to explicitly opt into?
    #
    # Let's see how it goes for now allowing any Enumerable to be a
    # sequence.
    def check_type(instance, &recursively_check_type)
      ::Enumerable === instance &&
      instance.all? {|i| recursively_check_type[@type, i]}
    end

    def shallow_check_type(instance)
      ::Enumerable === instance
    end

    def tag
      "Sequence"
    end

    attr_reader :type

    def to_string(depth, indent)
      "sequence(#{@type.to_s(depth+1, indent)})"
    end

    def canonicalize!
      @type = @type.target
    end

  end
end
