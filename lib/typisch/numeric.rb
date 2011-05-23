module Typisch
  class Type::Numeric < Type::Tagged
    def initialize(type)
      @type = type
    end
    
    TOWER = ["Complex", "Real", "Rational", "Integral"].map {|t| new(t)}
    Type::COMPLEX, Type::REAL, Type::RATIONAL, Type::INTEGRAL = *TOWER

    class << self
      private :new

      def top_type(*)
        Type::COMPLEX
      end
      
      def subgoals_to_prove_subtype(x, y)
        x.index_in_tower >= y.index_in_tower && []
      end
      
      def least_upper_bounds_for_union(*types)
        [types.min_by(&:index_in_tower)]
      end
    end

    def to_s
      @type
    end

    def tag
      @type
    end
    
    def index_in_tower
      TOWER.index {|t| t.equal?(self)}
    end    
  end
end