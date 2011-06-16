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

      # This l.u.b. isn't as tight as it could be;
      # (Int, Int) union (Bool, Bool) is a strict subset of
      # (Int union Bool, Int union Bool), see eg (1, true).
      #
      # It makes life simpler to do it this way though;
      # if you want to keep the distinction, try using
      # Object types with different type tags.
      def least_upper_bounds_for_union(*tuples)
        min_length = tuples.map(&:length).min
        unions = Array.new(min_length) do |i|
          Type::Union.union(*tuples.map {|t| t[i]})
        end
        [new(*unions)]
      end

    end

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

    attr_reader :types

    def length
      @types.length
    end

    def [](n)
      @types[n]
    end

    def tag
      "Tuple"
    end

    def to_s
      "(#{@types.join(', ')})"
    end

    def canonicalize(existing_canonicalizations={}, *)
      result = existing_canonicalizations[self] and return result
      result = existing_canonicalizations[self] = self.class.allocate
      result.send(:initialize, *@types.map {|t| t.canonicalize(existing_canonicalizations)})
      result
    end
  end
end
