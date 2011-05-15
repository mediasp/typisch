class Typisch::Type
  class Sequence < Tagged
    class << self
      def top_tag
        "Sequence"
      end
      Tagged::RESERVED_TAGS << top_tag

      def top_type(overall_top)
        new(overall_top)
      end
      
      def subgoals_to_prove_subtype(x, y)
        [x.type, y.type]
      end
    end

    def initialize(type)
      @type = type
    end

    attr_reader :type
    
    def to_s
      "[#{@types.join(', ')}]"
    end
  end
end