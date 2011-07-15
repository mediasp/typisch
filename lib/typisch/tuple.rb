class Typisch::Type
  class Tuple < Constructor
    class << self
      def top_type(overall_top)
        new()
      end

      def check_subtype(x, y, &recursively_check_subtype)
        if x.length >= y.length
          (0...y.length).all? {|i| recursively_check_subtype[x[i], y[i]]}
        end
      end
    end
    LATTICES << self

    def initialize(*types)
      @types = types
    end

    # For now we're only allowing Array as a tuple.
    # We could allow any Enumerable, say, but a tuple is really not supposed to be
    # in any way a lazy data structure, it's something of fixed (usually short) length.
    def check_type(instance, &recursively_check_type)
      ::Array === instance &&
      instance.length == @types.length &&
      @types.zip(instance).all?(&recursively_check_type)
    end

    def shallow_check_type(instance)
      ::Array === instance && instance.length == @types.length
    end


    attr_reader :types
    alias :subexpression_types :types

    def length
      @types.length
    end

    def [](n)
      @types[n]
    end

    def tag
      "Tuple"
    end

    def to_string(depth, indent)
      next_indent = "#{indent}  "
      types = @types.map {|t| t.to_s(depth+1, next_indent)}
      "tuple(\n#{next_indent}#{types.join(",\n#{next_indent}")}\n#{indent})"
    end

    def canonicalize!
      @types.map!(&:target)
    end
  end
end
