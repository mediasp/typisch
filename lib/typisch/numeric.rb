class Typisch::Type
  class Numeric < Tagged
    def initialize(type)
      @type
    end
    
    TOWER = ["Complex", "Real", "Rational", "Integral"].map {|t| new(t)}
    COMPLEX, REAL, RATIONAL, INTEGRAL = *TOWER

    class << self
      private :new

      def top_tag
        "Complex"
      end

      def top_type(*)
        COMPLEX
      end
      
      def subgoals_to_prove_subtype(x, y)
        TOWER.index(x) >= TOWER.index(y) && []
      end
    end

    def to_s
      @type
    end

    def tag
      @type
    end
  end
end