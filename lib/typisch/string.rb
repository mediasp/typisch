module Typisch
  class Type::String < Type::Constructor
    class << self
      def tag
        "String"
      end

      def top_type(*)
        @top_type ||= new
      end

      def check_subtype(x, y)
        x.equal?(y) || (
          x.max_length <= y.max_length &&
          (!y.values || (x.values && x.values.subset?(y.values)))
        )
      end
    end

    def initialize(refinements={})
      @refinements = refinements
      if @refinements[:values] && !@refinements[:values].is_a?(::Set)
        @refinements[:values] = ::Set.new(refinements[:values])
      end
    end

    Infinity = 1.0/0

    def max_length
      @refinements[:max_length] || Infinity
    end

    def values
      @refinements[:values]
    end

    def tag
      self.class.tag
    end

    def check_type(instance)
      ::String === instance &&
      (!values     || values.include?(instance)) &&
      (instance.length <= max_length)
    end

    def to_s(*)
      @name ? @name.inspect : "string(#{@refinements.inspect})"
    end

    def self.tag
      "String"
    end

    def shallow_check_type(instance)
      ::String === instance
    end

    Registry.register_global_type(:string, top_type)
  end
end
