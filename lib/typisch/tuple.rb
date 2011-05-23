class Typisch::Type
  class Tuple < Tagged
    class << self
      def top_type(overall_top)
        new()
      end
      
      def subgoals_to_prove_subtype(x, y)
        Array.new(y.length) {|i| [x[i], y[i]]} if x.length >= y.length
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
    Tagged::RESERVED_TAGS << "Tuple"
    
    def to_s
      "(#{@types.join(', ')})"
    end
  end
end