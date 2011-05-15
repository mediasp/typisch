class Typisch::Type
  class Tuple < Tagged
    class << self
      def top_tag
        "Tuple"
      end
      Tagged::RESERVED_TAGS << top_tag

      def top_type(overall_top)
        new()
      end
      
      def subgoals_to_prove_subtype(x, y)
        Array.new(y.length) {|i| [x[i], y[i]]} if x.length >= y.length
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
    
    def to_s
      "(#{@types.join(', ')})"
    end
  end
end