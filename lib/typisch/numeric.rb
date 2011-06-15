module Typisch
  class Type::Numeric < Type::Constructor
    def initialize(type)
      @type = type
    end

    TOWER = ["Complex", "Real", "Rational", "Integer"].map do |tag|
      type = new(tag)
      Registry.register_global_type(tag.downcase.to_sym, type)
      type
    end

    class << self
      private :new

      def top_type(*)
        TOWER.first
      end

      def check_subtype(x, y)
        x.index_in_tower >= y.index_in_tower
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
